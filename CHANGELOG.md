# VKE — Changelog

## 1.1.0 · 2026-08-21
- **Settings → Updates**: firmware-style update checker — current version, update channel,
  a Check-now button, and a shape-aware Update flow (native · appliance/watchtower · Helm).
- **Settings → Support tickets**: raise a ticket with text, image attachments, or an
  in-app screen capture — filed straight to the VKE issue tracker.
- **Clusters → attach & Discover**: auto-detect (in-cluster ServiceAccount → kubeconfig →
  demo snapshot with a clear banner, never empty screens), one-click Discover, paste-a-kubeconfig
  attach, and read-only docker-socket/URL container visibility.
- **In-cluster trainer**: the Helm chart's `trainer.enabled` adds the trainer sidecar — the
  Training Studio trains for real inside your cluster and imports the result into your Ollama.
- Namespace-scoped Act grants (`rbac.writeNamespaces`) — fenced writes per namespace, refused
  by the API server everywhere else.
- Durable alias state across container/pod restarts.

## 1.0.0 · 2026-08-20
- **The Training Studio**: pick a model → pick/upload data (JSONL/CSV, append) → cost-gated
  Estimate → Confirm launch → live loss with restart-restore → run history with a real
  v1-vs-v2 overlay → promote to a stable alias → test in place → chat with the result.
- **The self-contained appliance**: `docker compose up` with models (qwen2.5 1.5b + 0.5b),
  a real CPU LoRA trainer (HF base bundled) and the sre-pods datasets all inside —
  fully offline after the pull.
- **In-cluster deploys**: one `helm install` with a read-only-by-RBAC ServiceAccount.

## Earlier
- The full Observe · Converse · Act(+HITL) · Learn · Oversight · Admin console: ~35 role-gated
  tiles over one hash-chained event log, the safety fence (scale/restart, never delete),
  the approvals queue + Telegram, autonomy graduation (T0/T1/T2), analytics and the flywheel.
