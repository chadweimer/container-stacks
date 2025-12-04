# alloy

## Configuration

Additional alloy configuration can be provided via `*.alloy` files in the host path that is bound to `/etc/alloy`.
For example, if custom a scrape target is desired (e.g., another external computer), the following could be added:

```text
// machines.alloy

prometheus.scrape "machines" {
  targets = [{
    __address__ = "1.2.3.4:9100",
    instance    = "hostname",
  }]
  forward_to = [prometheus.remote_write.default.receiver]
  job_name   = "machines"
}
```
