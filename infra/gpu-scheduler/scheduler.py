#!/usr/bin/env python3
"""
GPU Priority Scheduler
Automatically manages GPU allocation between vLLM, ComfyUI, and Ollama.

Priority:
  1. vLLM  — paid gpt-4 API requests via LiteLLM (highest revenue)
  2. ComfyUI — AI content generation (scheduled 02:00–07:00 or when queue has jobs)
  3. Ollama — always-on systemd service, yields GPU when others need it

Logic (every 30s):
  - vLLM starts when gpt-4 requests detected in LiteLLM logs
  - vLLM stops after 10 min idle (frees GPU)
  - ComfyUI starts during content window or when queue > 0 AND vLLM is not running
  - Alerts all state changes to Telegram
"""

import subprocess
import time
import requests
import logging
import os
from datetime import datetime
from pathlib import Path

LITELLM_URL = os.getenv("LITELLM_URL", "http://localhost:4000")
LITELLM_KEY = os.getenv("LITELLM_MASTER_KEY", "")
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://localhost:8188")
VLLM_DIR    = os.getenv("VLLM_DIR",    "/home/yuri/income-services/vllm")
COMFYUI_DIR = os.getenv("COMFYUI_DIR", "/home/yuri/income-services/ai-content")
TELEGRAM_TOKEN   = os.getenv("TELEGRAM_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
LOG_DIR = Path("/home/yuri/income-services/shared/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "gpu-scheduler.log"),
        logging.StreamHandler(),
    ],
)
log = logging.getLogger(__name__)


def alert(msg: str):
    log.info(f"ALERT: {msg}")
    if not TELEGRAM_TOKEN or not TELEGRAM_CHAT_ID:
        return
    try:
        requests.post(
            f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
            json={"chat_id": TELEGRAM_CHAT_ID, "text": f"🖥️ {msg}"},
            timeout=5,
        )
    except Exception:
        pass


def is_container_running(name: str) -> bool:
    r = subprocess.run(
        ["docker", "inspect", "-f", "{{.State.Running}}", name],
        capture_output=True, text=True,
    )
    return r.stdout.strip() == "true"


def compose_up(directory: str):
    subprocess.run(["docker", "compose", "up", "-d"], cwd=directory, capture_output=True)


def compose_down(directory: str):
    subprocess.run(["docker", "compose", "down"], cwd=directory, capture_output=True)


def gpu_utilization() -> int:
    r = subprocess.run(
        ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"],
        capture_output=True, text=True,
    )
    try:
        return int(r.stdout.strip())
    except ValueError:
        return 0


def recent_gpt4_requests() -> int:
    """Count gpt-4 (vLLM) calls in the last 10 minutes via LiteLLM spend logs."""
    try:
        r = requests.get(
            f"{LITELLM_URL}/spend/logs?limit=100",
            headers={"Authorization": f"Bearer {LITELLM_KEY}"},
            timeout=5,
        )
        if r.status_code != 200:
            return 0
        now = time.time()
        return sum(
            1 for e in r.json()
            if e.get("model") == "gpt-4" and now - e.get("startTime", 0) < 600
        )
    except Exception:
        return 0


def comfyui_queue_size() -> int:
    try:
        r = requests.get(f"{COMFYUI_URL}/queue", timeout=5)
        d = r.json()
        return len(d.get("queue_running", [])) + len(d.get("queue_pending", []))
    except Exception:
        return 0


def in_content_window() -> bool:
    """02:00–07:00 SP time: off-peak, dedicated to ComfyUI batch generation."""
    return 2 <= datetime.now().hour < 7


vllm_idle_since: float = 0.0


def tick():
    global vllm_idle_since

    vllm_up     = is_container_running("vllm-server")
    comfyui_up  = is_container_running("comfyui")
    gpt4_reqs   = recent_gpt4_requests()
    comfyui_q   = comfyui_queue_size()
    gpu_pct     = gpu_utilization()

    log.info(
        f"vLLM={vllm_up} ComfyUI={comfyui_up} "
        f"gpt4_req={gpt4_reqs} comfyui_q={comfyui_q} GPU={gpu_pct}%"
    )

    # ── vLLM ─────────────────────────────────────────────
    if gpt4_reqs > 0:
        vllm_idle_since = 0.0
        if not vllm_up:
            alert("Starting vLLM: paid gpt-4 requests detected 🚀")
            compose_up(VLLM_DIR)
    else:
        if vllm_idle_since == 0.0:
            vllm_idle_since = time.time()
        idle_secs = time.time() - vllm_idle_since
        if vllm_up and idle_secs > 600:
            alert("Stopping vLLM after 10 min idle — GPU freed ✅")
            compose_down(VLLM_DIR)
            vllm_idle_since = 0.0

    # ── ComfyUI (only when vLLM isn't using GPU) ─────────
    if not vllm_up:
        needs_comfyui = comfyui_q > 0 or in_content_window()
        if needs_comfyui and not comfyui_up:
            reason = "queued jobs" if comfyui_q > 0 else "content window"
            alert(f"Starting ComfyUI ({reason}) 🎨")
            compose_up(COMFYUI_DIR)
        elif comfyui_up and not needs_comfyui:
            alert("Stopping ComfyUI — queue empty, outside content window 💤")
            compose_down(COMFYUI_DIR)
    else:
        # vLLM is running, stop ComfyUI if it's somehow up
        if comfyui_up:
            alert("Stopping ComfyUI — vLLM needs full GPU ⚠️")
            compose_down(COMFYUI_DIR)


def main():
    alert("GPU Scheduler started 🟢")
    while True:
        try:
            tick()
        except Exception as e:
            log.error(f"tick() error: {e}")
        time.sleep(30)


if __name__ == "__main__":
    main()
