# Integration Tests + Config Fix Design

Date: 2026-03-18

## Problem

1. `config(dsl)` in the plugin uses `define_method` via `instance_eval` on a `Puma::DSL` instance — `define_method` is a `Module` method, not available on instances. This crashes on real Puma startup.
2. No integration tests exist — only unit tests with mocked launcher.

## Solution

### Config fix: remove DSL extension

Remove `config(dsl)` from the plugin entirely. Configuration via `PumaPluginHealthCheck.configure { |c| ... }` already works and is the standard pattern for Puma plugins (built-in plugins like `tmp_restart` and `systemd` don't use `config(dsl)` either).

User configures in `puma.rb`:

```ruby
require 'puma_plugin_health_check'
PumaPluginHealthCheck.configure do |c|
  c.port = 9494
  c.liveness_path = '/health'
end
plugin :health_check
```

### Integration tests via CLI process

Spawn `bundle exec puma` as a subprocess with test config files.

**Files:**

```
spec/
  integration/
    puma_integration_spec.rb
  fixtures/
    app.rb              # minimal Rack app
    puma_basic.rb       # default config
    puma_custom.rb      # custom port and paths
```

**Test cases:**

1. Basic startup — liveness returns 200
2. Readiness in single-mode — returns 200
3. Unknown path — returns 404
4. Custom config — custom port and paths work
5. Graceful shutdown — process exits cleanly on TERM

**Mechanics:**

- `Process.spawn` with stdout/stderr captured
- Parse health check port from Puma log output (`Health check server listening on 0.0.0.0:XXXX`)
- TCP polling with 10s timeout for startup readiness
- `after(:each)` cleanup: `Process.kill('TERM', pid)` + `Process.wait`
- RSpec tag `:integration` for selective running
