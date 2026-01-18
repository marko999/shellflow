# Spawn Watcher

Create a monitoring pane/window running a long-lived command.

## Input
`$ARGUMENTS` = `<name> <command>`

Examples:
- `/spawn-watcher api-logs kubectl logs -f -l app=api`
- `/spawn-watcher rabbit watch -n 2 rabbitmqctl list_queues`
- `/spawn-watcher pods kubectl get pods -w`
- `/spawn-watcher build npm run build --watch`
- `/spawn-watcher env kubectl exec -it pod/api -- env | grep -E "^(DB|API|AUTH)"`

## Steps

1. **Parse arguments**: Extract `<name>` (first word) and `<command>` (rest of the line)

2. **Create tmux window**:
   ```bash
   tmux new-window -n "watch-<name>"
   ```

3. **Run the command**:
   ```bash
   tmux send-keys -t "watch-<name>" "<command>" Enter
   ```

## Confirmation
Output:
```
✓ Watcher 'watch-<name>' started
  Command: <command>
  View: tmux select-window -t watch-<name>
```

## Common Watcher Commands Reference

### Kubernetes
- Pod logs: `kubectl logs -f -l app=<app>`
- Watch pods: `kubectl get pods -w`
- Pod resources: `watch -n 5 kubectl top pods`
- Events: `kubectl get events -w`

### Message Queues
- RabbitMQ queues: `watch -n 2 rabbitmqctl list_queues`
- Redis monitor: `redis-cli monitor`

### Builds/Tests
- Watch tests: `npm run test -- --watch`
- Watch build: `npm run build --watch`
- File changes: `fswatch -r ./src`

### System
- Processes: `htop` or `top`
- Network: `watch -n 1 'netstat -an | grep LISTEN'`
- Disk: `watch -n 5 df -h`
