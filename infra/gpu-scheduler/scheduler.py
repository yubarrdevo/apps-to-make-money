#!/usr/bin/env python3
"""
GPU Scheduler — auto-manages vLLM and ComfyUI on yuserver.

Rules:
  • vLLM  : start when LiteLLM receives gpt-4/smart requests; stop after
            VLLM_IDLE_TIMEOUT seconds of no gpt-4 traffic.
  • ComfyUI: start during the nightly content window (02:00–07:00) OR when
             the ComfyUI queue is non-empty, but ONLY when vLLM is idle.
  • Both services share the single RTX 3060 — they never run simultaneously.
  • All state changes are logged and sent to Telegram.

Configuration is read from the EnvironmentFile set in gpu-scheduler.service:
  ~/income-services/shared/.gpu-scheduler.env
"""

import os
import time
import logging
import subprocess
import datetime
import urllib.request
import urllib.error
import json

# ── Configuration (from environment, with sensible defaults) ─────────────────
LITELLM_URL        = os.getenv("LITELLM_URL", "http://localhost:4000")
LITELLM_MASTER_KEY = os.getenv("LITELLM_MASTER_KEY", "")
COMFYUI_URL        = os.getenv("COMFYUI_URL", "http://localhost:8188")
VLLM_DIR           = os.getenv("VLLM_DIR", "/home/yuri/income-services/vllm")
COMFYUI_DIR        = os.getenv("COMFYUI_DIR", "/home/yuri/income-services/ai-content")
TELEGRAM_TOKEN     = os.getenv("TELEGRAM_TOKEN", "")
TELEGRAM_CHAT_ID   = os.getenv("TELEGRAM_CHAT_ID", "")

POLL_INTERVAL      = int(os.getenv("POLL_INTERVAL", "30"))       # seconds
VLLM_IDLE_TIMEOUT  = int(os.getenv("VLLM_IDLE_TIMEOUT", "600"))  # 10 min
CONTENT_WINDOW_START = int(os.getenv("CONTENT_WINDOW_START", "2"))  # 02:00
CONTENT_WINDOW_END   = int(os.getenv("CONTENT_WINDOW_END",   "7"))  # 07:00

LOG_FILE = "/home/yuri/income-services/shared/logs/gpu-scheduler.log"

# ── Logging ──────────────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(),
    ],
)
log = logging.getLogger("gpu-scheduler")

# ── Telegram ─────────────────────────────────────────────────────────────────
def telegram(msg: str) -> None:
    """Send a Telegram message; silently ignore errors."""
    if not TELEGRAM_TOKEN or not TELEGRAM_CHAT_ID:
        return
    try:
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        payload = json.dumps({"chat_id": TELEGRAM_CHAT_ID, "text": msg}).encode()
        req = urllib.request.Request(url, data=payload,
                                     headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=10)
    except Exception as exc:
        log.warning("Telegram send failed: %s", exc)

# ── Docker Compose helpers ────────────────────────────────────────────────────
def _compose(directory: str, *args: str) -> bool:
    """Run docker compose <args> in directory. Returns True on success."""
    try:
        result = subprocess.run(
            ["docker", "compose", *args],
            cwd=directory,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            log.error("docker compose %s failed: %s", " ".join(args), result.stderr.strip())
            return False
        return True
    except Exception as exc:
        log.error("docker compose error: %s", exc)
        return False


def service_running(container_name: str) -> bool:
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", f"name=^{container_name}$",
             "--filter", "status=running", "--format", "{{.Names}}"],
            capture_output=True, text=True, timeout=10,
        )
        return container_name in result.stdout
    except Exception:
        return False


def start_vllm() -> None:
    log.info("Starting vLLM...")
    if _compose(VLLM_DIR, "up", "-d"):
        log.info("vLLM started")
        telegram("🚀 vLLM started — GPU now serving gpt-4 requests")
    else:
        log.error("Failed to start vLLM")
        telegram("❌ vLLM failed to start — check logs")


def stop_vllm() -> None:
    log.info("Stopping vLLM (idle)...")
    if _compose(VLLM_DIR, "down"):
        log.info("vLLM stopped")
        telegram("💤 vLLM stopped — GPU freed after idle timeout")
    else:
        log.error("Failed to stop vLLM")


def start_comfyui() -> None:
    log.info("Starting ComfyUI...")
    if _compose(COMFYUI_DIR, "up", "-d"):
        log.info("ComfyUI started")
        telegram("🎨 ComfyUI started — AI content generation active")
    else:
        log.error("Failed to start ComfyUI")
        telegram("❌ ComfyUI failed to start — check logs")


def stop_comfyui() -> None:
    log.info("Stopping ComfyUI...")
    if _compose(COMFYUI_DIR, "down"):
        log.info("ComfyUI stopped")
        telegram("🛑 ComfyUI stopped")
    else:
        log.error("Failed to stop ComfyUI")

# ── LiteLLM metrics ──────────────────────────────────────────────────────────
def get_litellm_spend_logs(since_minutes: int = 2) -> list:
    """
    Fetch recent LiteLLM spend logs and return entries for gpt-4/smart models.
    Returns an empty list on any error (treat as no traffic).
    """
    try:
        url = f"{LITELLM_URL}/spend/logs"
        req = urllib.request.Request(url)
        if LITELLM_MASTER_KEY:
            req.add_header("Authorization", f"Bearer {LITELLM_MASTER_KEY}")
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode())
        if not isinstance(data, list):
            return []

        cutoff = datetime.datetime.utcnow() - datetime.timedelta(minutes=since_minutes)
        gpu_models = {"gpt-4", "smart"}
        recent = []
        for entry in data:
            model = (entry.get("model") or "").lower()
            ts_raw = entry.get("startTime") or entry.get("start_time") or ""
            if model in gpu_models and ts_raw:
                try:
                    ts = datetime.datetime.fromisoformat(ts_raw.replace("Z", "+00:00"))
                    ts = ts.replace(tzinfo=None)
                    if ts >= cutoff:
                        recent.append(entry)
                except ValueError:
                    pass
        return recent
    except Exception as exc:
        log.debug("LiteLLM metrics fetch failed: %s", exc)
        return []


def comfyui_has_queued_jobs() -> bool:
    """Return True if ComfyUI reports pending jobs in its queue."""
    try:
        url = f"{COMFYUI_URL}/queue"
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read().decode())
        pending = data.get("queue_pending", [])
        running = data.get("queue_running", [])
        return len(pending) > 0 or len(running) > 0
    except Exception:
        return False


def in_content_window() -> bool:
    now = datetime.datetime.now().hour
    return CONTENT_WINDOW_START <= now < CONTENT_WINDOW_END

# ── Main loop ─────────────────────────────────────────────────────────────────
def main() -> None:
    log.info("GPU scheduler started (poll=%ds, vllm_idle=%ds)", POLL_INTERVAL, VLLM_IDLE_TIMEOUT)
    telegram("✅ GPU scheduler started on yuserver")

    vllm_last_active: float = 0.0  # epoch timestamp of last gpt-4 request seen

    while True:
        try:
            vllm_up     = service_running("vllm")
            comfyui_up  = service_running("comfyui")

            # ── vLLM demand check ────────────────────────────────────────────
            recent_gpt4 = get_litellm_spend_logs(since_minutes=2)
            has_gpt4_traffic = len(recent_gpt4) > 0

            if has_gpt4_traffic:
                vllm_last_active = time.time()

            idle_seconds = time.time() - vllm_last_active if vllm_last_active else float("inf")

            # Start vLLM if there's demand and it's not running
            if has_gpt4_traffic and not vllm_up:
                if comfyui_up:
                    stop_comfyui()
                    comfyui_up = False
                start_vllm()
                vllm_up = True

            # Stop vLLM after idle timeout
            elif vllm_up and idle_seconds >= VLLM_IDLE_TIMEOUT:
                stop_vllm()
                vllm_up = False
                vllm_last_active = 0.0

            # ── ComfyUI demand check (only when vLLM is idle) ────────────────
            if not vllm_up:
                want_comfyui = in_content_window() or comfyui_has_queued_jobs()

                if want_comfyui and not comfyui_up:
                    start_comfyui()
                    comfyui_up = True
                elif not want_comfyui and comfyui_up:
                    stop_comfyui()
                    comfyui_up = False

        except Exception as exc:
            log.exception("Unexpected error in scheduler loop: %s", exc)

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
