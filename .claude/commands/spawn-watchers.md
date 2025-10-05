# Spawn Watcher Dashboard

Create a monitoring dashboard with multiple predefined watcher panes.

## Input
`$ARGUMENTS` = Preset name OR comma-separated list of `<name>:<command>` pairs

### Presets

**`/spawn-watchers k8s`** - Kubernetes monitoring:
```
┌─────────────────┬─────────────────┐
│ pods            │ logs            │
│ kubectl get -w  │ kubectl logs -f │
├─────────────────┼─────────────────┤
│ events          │ resources       │
│ kubectl events  │ kubectl top     │
└─────────────────┴─────────────────┘
```

**`/spawn-watchers docker`** - Docker monitoring:
```
┌─────────────────┬─────────────────┐
│ containers      │ logs            │
│ docker ps       │ docker logs -f  │
├─────────────────┴─────────────────┤
│ stats                             │
│ docker stats                      │
└───────────────────────────────────┘
```

**`/spawn-watchers dev`** - Development monitoring:
```
┌─────────────────┬─────────────────┐
│ tests           │ build           │
│ npm test:watch  │ npm run build:w │
├─────────────────┼─────────────────┤
│ git             │ files           │
│ watch git status│ fswatch src/    │
└─────────────────┴─────────────────┘
```

**`/spawn-watchers rabbit`** - RabbitMQ monitoring:
```
┌─────────────────────────────────────┐
│ queues                              │
│ watch rabbitmqctl list_queues       │
├─────────────────────────────────────┤
│ connections                         │
│ watch rabbitmqctl list_connections  │
└─────────────────────────────────────┘
```

### Custom
**`/spawn-watchers pods:kubectl get pods -w, logs:kubectl logs -f app, top:htop`**

## Steps

1. **Parse input** - determine if preset or custom

2. **Create watcher window**:
   ```bash
   tmux new-window -n "watchers"
   ```

3. **Create panes based on layout**:

   For 4-pane grid (2x2):
   ```bash
   # Start in pane 0
   tmux send-keys -t watchers "<cmd1>" Enter

   # Split right for pane 1
   tmux split-window -h -t watchers
   tmux send-keys -t watchers "<cmd2>" Enter

   # Go to pane 0, split down for pane 2
   tmux select-pane -t watchers.0
   tmux split-window -v -t watchers
   tmux send-keys -t watchers "<cmd3>" Enter

   # Go to pane 1, split down for pane 3
   tmux select-pane -t watchers.1
   tmux split-window -v -t watchers
   tmux send-keys -t watchers "<cmd4>" Enter
   ```

4. **Balance panes**:
   ```bash
   tmux select-layout -t watchers tiled
   ```

5. **Report**:
   ```
   ✓ Created watcher dashboard 'watchers'

   Panes:
   1. pods    - kubectl get pods -w
   2. logs    - kubectl logs -f -l app=api
   3. events  - kubectl get events -w
   4. top     - kubectl top pods

   View: tmux select-window -t watchers
   ```

## Preset Definitions

### k8s (Kubernetes)
```
- pods: kubectl get pods -w
- logs: kubectl logs -f -l app=${APP:-app} --tail=100
- events: kubectl get events -w
- resources: watch -n 5 kubectl top pods
```

### docker
```
- containers: watch -n 2 docker ps
- logs: docker logs -f $(docker ps -q | head -1)
- stats: docker stats
```

### dev
```
- tests: npm run test -- --watch 2>/dev/null || echo "No test:watch script"
- build: npm run build -- --watch 2>/dev/null || echo "No build:watch script"
- git: watch -n 5 git status --short
- files: fswatch -r ./src 2>/dev/null || watch -n 2 'ls -la src/'
```

### rabbit
```
- queues: watch -n 2 'rabbitmqctl list_queues name messages consumers 2>/dev/null || echo "RabbitMQ not available"'
- connections: watch -n 5 'rabbitmqctl list_connections 2>/dev/null || echo "RabbitMQ not available"'
```

### Custom Example
```
/spawn-watchers cpu:htop, mem:watch free -h, disk:watch df -h, net:watch netstat -i
```
