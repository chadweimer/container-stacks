# Homepage

A modern, highly customizable application dashboard with Docker integration and service widgets.

## Initial Setup

1. Homepage configuration files are located in `${DATA_DIR:-/mnt/pool0/containers}/homepage`.
2. Add your services, bookmarks, and widgets in `services.yaml`, `widgets.yaml`, and `settings.yaml`.
3. Homepage connects to `docker-proxy` to discover running containers and display live statuses.
