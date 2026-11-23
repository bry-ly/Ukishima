#!/usr/bin/env python3
"""Read OpenCode Go usage and local OpenCode token stats as JSON.

The subscription meters come from OpenCode's own usage endpoint using the
credential OpenCode already stores in its database. Local token totals come
from the same database's assistant messages, so no extra collector runs and
no credential is copied anywhere.

Output is one object: {"providers": [record], "error": ""}. The record carries
the provider name, plan tier, limit windows with reset times, and local token
totals for today and the last seven days.
"""

import json
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

API_BASE = "https://opencode.ai"
KEY_USAGE = "/zen/go/v1/usage"
OAUTH_USAGE = "/inference/go/v1/usage"
ORG_HEADER = "x-opencode-org-id"
TIMEOUT = 12

PROVIDERS = ("opencode-go", "opencode")


def state_home() -> Path:
    configured = os.environ.get("XDG_STATE_HOME", "").strip()
    return Path(configured).expanduser() if configured else Path.home() / ".local" / "state"


def data_home() -> Path:
    configured = os.environ.get("XDG_DATA_HOME", "").strip()
    return Path(configured).expanduser() if configured else Path.home() / ".local" / "share"


def opencode_db() -> Path:
    root = data_home() / "opencode"
    configured = os.environ.get("OPENCODE_DB", "").strip()
    if configured:
        path = Path(configured).expanduser()
        return path if path.is_absolute() else root / path
    normal = root / "opencode.db"
    legacy = root / "opencode-v2.db"
    return legacy if not normal.is_file() and legacy.is_file() else normal


def number(value) -> float:
    try:
        result = float(value)
        return result if result == result else 0.0
    except (TypeError, ValueError):
        return 0.0


def token(value) -> int:
    try:
        return max(0, int(float(value)))
    except (TypeError, ValueError):
        return 0


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_credential(conn):
    """The active OpenCode/Go credential, preferring the Go id."""
    try:
        row = conn.execute(
            "SELECT value FROM credential WHERE active = 1"
            " AND integration_id IN ('opencode-go', 'opencode')"
            " ORDER BY integration_id = 'opencode-go' DESC, time_updated DESC LIMIT 1"
        ).fetchone()
    except sqlite3.Error:
        return None
    if not row:
        return None
    try:
        value = json.loads(row[0])
    except Exception:
        return None
    if not isinstance(value, dict):
        return None
    return value


def credential_token(credential):
    if not isinstance(credential, dict):
        return ""
    if credential.get("type") == "oauth":
        return str(credential.get("access") or "").strip()
    key = credential.get("key")
    if isinstance(key, str) and key.strip() and not key.strip().startswith(("!", "$")):
        return key.strip()
    return ""


def probe_limits(credential):
    """(limits, tier, helpText) from OpenCode's usage endpoint."""
    empty = ([], "", "")
    if not isinstance(credential, dict):
        return empty
    token_value = credential_token(credential)
    if not token_value:
        return empty

    oauth = credential.get("type") == "oauth"
    headers = {
        "Authorization": "Bearer " + token_value,
        "Accept": "application/json",
        "User-Agent": "ukishima-ai-usage/1.0",
    }
    url = API_BASE + (OAUTH_USAGE if oauth else KEY_USAGE)
    if oauth:
        metadata = credential.get("metadata")
        org = str(metadata.get("orgID") or "").strip() if isinstance(metadata, dict) else ""
        if org:
            headers[ORG_HEADER] = org
        expires = number(credential.get("expires"))
        if 0 < expires <= time.time() * 1000:
            return empty

    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        if error.code in (401, 403):
            return ([], "", "OpenCode rejected the saved credential. Reconnect the plan with `opencode auth login`.")
        return ([], "", "OpenCode's usage endpoint returned status %d." % error.code)
    except Exception:
        return ([], "", "Could not reach OpenCode's usage endpoint. Local stats are still shown.")

    usage = payload.get("usage") if isinstance(payload, dict) else None
    if not isinstance(usage, dict):
        usage = payload if isinstance(payload, dict) else {}
    limits = []
    for key, label in (("rolling", "5h"), ("weekly", "Weekly"), ("monthly", "Monthly")):
        window = usage.get(key)
        if not isinstance(window, dict):
            window = payload.get(key + "Usage") if isinstance(payload, dict) else None
        if not isinstance(window, dict):
            continue
        percent = window.get("percent", window.get("usagePercent"))
        if not isinstance(percent, (int, float)) or isinstance(percent, bool):
            continue
        percent = max(0.0, min(1.0, number(percent) / 100.0))
        if str(window.get("status") or "") == "rate-limited":
            percent = 1.0
        limits.append({
            "label": label,
            "percent": percent,
            "resetsAt": window.get("resetsAt") or "",
        })
    return (limits, "Go" if limits else "", "")


def local_stats(conn):
    """Token totals, sessions, seven-day series and per-model buckets."""
    today = datetime.now().date()
    days = [(today - timedelta(days=offset)).isoformat() for offset in range(6, -1, -1)]
    recent = {day: 0 for day in days}
    models = {}
    sessions = set()
    today_sessions = set()
    total_tokens = 0
    today_tokens = 0
    total_replies = 0
    today_replies = 0

    try:
        rows = conn.execute(
            "SELECT session_id, type, time_created, data FROM session_message"
            " WHERE type IN ('assistant', 'compaction')"
        ).fetchall()
    except sqlite3.Error:
        rows = []

    for session_id, row_type, created, raw in rows:
        try:
            entry = json.loads(raw)
        except Exception:
            continue
        if not isinstance(entry, dict):
            continue
        model = entry.get("model") if isinstance(entry.get("model"), dict) else {}
        provider = str(model.get("providerID") or entry.get("providerID") or "")
        if provider not in PROVIDERS:
            continue
        tokens = entry.get("tokens") if isinstance(entry.get("tokens"), dict) else {}
        cache = tokens.get("cache") if isinstance(tokens.get("cache"), dict) else {}
        input_tokens = token(tokens.get("input"))
        output_tokens = token(tokens.get("output")) + token(tokens.get("reasoning"))
        cache_read = token(cache.get("read"))
        cache_write = token(cache.get("write"))
        amount = input_tokens + output_tokens + cache_read + cache_write
        if amount <= 0:
            continue
        model_time = entry.get("time") if isinstance(entry.get("time"), dict) else {}
        stamp = number(model_time.get("created")) or number(created)
        try:
            day = datetime.fromtimestamp(stamp / 1000).date().isoformat() if stamp > 0 else today.isoformat()
        except (OverflowError, OSError, ValueError):
            day = today.isoformat()
        model_id = str(model.get("id") or model.get("modelID") or "unknown")
        total_tokens += amount
        total_replies += 1
        sessions.add(str(session_id))
        if day == today.isoformat():
            today_tokens += amount
            today_replies += 1
            today_sessions.add(str(session_id))
        if day in recent:
            recent[day] += amount
        bucket = models.setdefault(model_id, {
            "inputTokens": 0,
            "outputTokens": 0,
            "cacheReadInputTokens": 0,
            "cacheCreationInputTokens": 0,
        })
        bucket["inputTokens"] += input_tokens
        bucket["outputTokens"] += output_tokens
        bucket["cacheReadInputTokens"] += cache_read
        bucket["cacheCreationInputTokens"] += cache_write

    return {
        "todayTokens": today_tokens,
        "todayPrompts": today_replies,
        "todaySessions": len(today_sessions),
        "weekTokens": sum(recent.values()),
        "totalTokens": total_tokens,
        "totalPrompts": total_replies,
        "totalSessions": len(sessions),
        "recentDays": [{"date": day, "tokens": recent[day]} for day in days],
        "modelUsage": models,
    }


def omarchy_records():
    """Other agents' records written by Omarchy's collectors, if present.

    Ukishima does not ship Omarchy's per-provider collectors, but anyone who
    has them can point both shells at the same usage directory. The record
    contract is close enough to translate the few field names that differ.
    """
    directory = state_home() / "omarchy" / "agents" / "usage"
    if not directory.is_dir():
        return []
    output = []
    for path in sorted(directory.glob("*.json")):
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(value, dict) or value.get("ready") is False:
            continue
        name = str(value.get("name") or value.get("id") or "").strip()
        if not name:
            continue
        days = value.get("recentDays") if isinstance(value.get("recentDays"), list) else []
        recent = []
        for day in days:
            if isinstance(day, dict) and day.get("date"):
                recent.append({
                    "date": str(day.get("date")),
                    "tokens": token(day.get("messageCount")),
                })
        models = value.get("modelUsage") if isinstance(value.get("modelUsage"), dict) else {}
        total = 0
        for bucket in models.values():
            if not isinstance(bucket, dict):
                continue
            total += token(bucket.get("inputTokens")) + token(bucket.get("outputTokens"))
            total += token(bucket.get("cacheReadInputTokens")) + token(bucket.get("cacheCreationInputTokens"))
        output.append({
            "schemaVersion": 1,
            "id": str(value.get("id") or path.stem),
            "name": name,
            "tierLabel": str(value.get("tierLabel") or ""),
            "updatedAt": str(value.get("updatedAt") or ""),
            "ready": True,
            "hasLocalStats": bool(value.get("hasLocalStats")),
            "limits": value.get("limits") if isinstance(value.get("limits"), list) else [],
            "limitsStale": bool(value.get("limitsStale")),
            "authHelpText": str(value.get("authHelpText") or ""),
            "todayTokens": token(value.get("todayTotalTokens", value.get("todayTokens"))),
            "todayPrompts": token(value.get("todayPrompts")),
            "todaySessions": token(value.get("todaySessions")),
            "weekTokens": sum(day["tokens"] for day in recent),
            "totalTokens": total or token(value.get("totalTokens")),
            "totalPrompts": token(value.get("totalPrompts")),
            "totalSessions": token(value.get("totalSessions")),
            "recentDays": recent,
            "modelUsage": models,
        })
    return output


def main():
    db = opencode_db()
    if not db.is_file():
        external = omarchy_records()
        print(json.dumps({
            "providers": external,
            "error": "" if external else "OpenCode's database was not found.",
        }, separators=(",", ":")))
        return

    try:
        conn = sqlite3.connect(db.resolve().as_uri() + "?mode=ro", uri=True, timeout=2)
        conn.execute("PRAGMA query_only = ON")
    except sqlite3.Error as error:
        external = omarchy_records()
        print(json.dumps({
            "providers": external,
            "error": "" if external else "Could not open OpenCode's database: %s" % error,
        }, separators=(",", ":")))
        return

    try:
        credential = read_credential(conn)
        stats = local_stats(conn)
    finally:
        conn.close()

    limits, tier, help_text = probe_limits(credential)
    ready = bool(limits) or stats["totalTokens"] > 0 or bool(credential)
    record = {
        "schemaVersion": 1,
        "id": "opencode",
        "name": "OpenCode",
        "tierLabel": tier,
        "updatedAt": iso_now(),
        "ready": ready,
        "hasLocalStats": stats["totalTokens"] > 0,
        "limits": limits,
        "limitsStale": False,
        "authHelpText": help_text,
        **stats,
    }
    providers = [record] if ready else []
    providers += omarchy_records()
    print(json.dumps({"providers": providers, "error": ""}, separators=(",", ":")))


if __name__ == "__main__":
    main()
