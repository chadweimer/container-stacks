# Smart Home

Unified home automation stack including:
- **Home Assistant**: Open-source home automation hub.
- **Homebridge**: Apple HomeKit bridge for devices without native support.
- **Mosquitto**: MQTT message broker.
- **Z-Wave JS UI**: Z-Wave controller and web management.
- **Frigate NVR**: Real-time AI object detection video recorder.

## Initial Setup

1. Copy `example.env` to `.env` and configure passwords and API keys.
2. Verify hardware device passthroughs in `compose.yaml` (e.g., Coral TPU USB, Z-Wave USB sticks, `/dev/dri`).
3. Connect Home Assistant and Frigate to the Mosquitto MQTT broker.
