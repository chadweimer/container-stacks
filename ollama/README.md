# Ollama & Open WebUI

Self-hosted local Large Language Models (LLMs) with hardware acceleration and the Open WebUI web chat interface.

## Initial Setup

1. Configure `WEBUI_SECRET_KEY` in `.env`.
2. Ensure GPU / iGPU render devices (`/dev/dri`) are accessible on your host.
3. Access Open WebUI at `https://open-webui.${BASE_DOMAIN}` to download models (e.g. `llama3`, `mistral`) and start chatting.
