# puma-plugin-health-check

Lightweight Puma plugin that exposes Kubernetes-style liveness and readiness health check endpoints on a separate TCP port.

The health check server uses a raw `TCPServer` — no Rack overhead, responds even when your app is under heavy load.

## Installation

Add to your Gemfile:

```ruby
gem 'puma-plugin-health-check'
```

## Usage

In your `config/puma.rb`:

```ruby
plugin :health_check
```

That's it! The health check server starts on port 9393 with default paths.

### Custom configuration

```ruby
plugin :health_check

health_check do |hc|
  hc.port = 8080                            # default: 9393
  hc.bind = '127.0.0.1'                     # default: '0.0.0.0'
  hc.liveness_path = '/healthz/live'        # default: '/checks/_liveness'
  hc.readiness_path = '/healthz/ready'      # default: '/checks/_readiness'
end
```

## Endpoints

| Endpoint | Description | Status |
|---|---|---|
| Liveness path | Process is alive | Always `200` |
| Readiness path | Workers are booted | `200` if all workers booted, `503` otherwise. In single mode (no workers), always `200`. |
| Any other path | Not found | `404` |

## Kubernetes example

```yaml
livenessProbe:
  httpGet:
    path: /checks/_liveness
    port: 9393
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /checks/_readiness
    port: 9393
  initialDelaySeconds: 5
  periodSeconds: 10
```

## License

MIT
