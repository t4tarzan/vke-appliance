# VKE — Changelog

## 1.4.0 · 2026-08-24
- **Verified sealed, again**: the whole air-gap edition re-proven from scratch — sealed acceptance
  walk green three times (including against this release's own image), a packet capture showing zero
  egress from the sealed network, a 42-screen browser walk with zero errors, and 43 new automated
  tests covering the gateway, API keys, workspaces, knowledge search and the tamper-evident history.
- **Everything is clickable**: every record on every screen opens a right-side detail drawer —
  history rows show their chain-verified receipt, learned fixes show their full track record, models
  open a live model card (training lineage, dataset + privacy stats, promote history), datasets show
  sample rows and their schema.
- **Incidents tell their whole story**: the six-section incident walk (Signal → Learning) now
  populates end to end — fixes, approvals, actions, outcomes and retraining are correlated to the
  incident, older incidents included; duplicate cluster events collapse behind count badges; a
  "Diagnose in chat" handoff records the conversation on the incident's trail.
- **Model provenance in chat**: the model picker shows a trained model's version and promote date
  ("k8s-sre · v3 · Aug 24"), with a one-click model card.
- **Robust Settings**: an air-gap status card (and whether the seal comes from the environment or a
  setting), every status pill opens a detail drawer, and invalid values are blocked with the reason
  shown instead of silently saved.
- **A real network instrument under Discover**: node network identity, CNI detection, cluster-DNS
  health, API-server latency percentiles, services with no endpoints behind them, an outage rollup
  from the cluster's own events, and an opt-in read-only throughput estimate — every probe
  intranet-only.
- **Durability fixes**: the event hash chain can no longer fork under concurrent writes; receipts
  are workspace-scoped; failed API calls keep their receipt link.

## 1.3.0 · 2026-08-23
- **Air-gap edition (the vke-airgap arc, complete)**: the platform now runs with ZERO internet,
  forever — one master seal (`VKE_AIRGAP=1`) turns off every egress class, proven with a network
  canary and a packet capture showing nothing ever leaves.
- **The governed API gateway (`/api/v1`)**: standard OpenAI-compatible chat/embeddings for
  hundreds of intranet users — per-key quotas, exact metering, and a tamper-evident RECEIPT on
  every answer; 27ms p95 gateway overhead at 300 concurrent live streams.
- **Department workspaces**: each department gets its own API keys, model personas, datasets,
  knowledge collections and audit stream — proven fully isolated from each other.
- **Knowledge with citations (RAG v2)**: answers ground in the department's documents and the
  estate's own ops history; every citation deep-links to the exact highlighted passage. The
  platform files its own incidents, syslog and meeting recordings into the same library.
- **Five ingest doors, one pipeline**: webhook, watched file-drop/SMB folder, MinIO/S3 pull,
  read-only Postgres pull and a syslog listener — everything normalized and PII-vaulted.
- **Identity**: optional LDAP and Keycloak (OpenID Connect) sign-in with group→role/workspace
  mapping; PIN login always keeps working.
- **MCP server (`/mcp`)**: one URL plugs an employee's IDE/agent client into the department's
  model, knowledge and approved tools — proven with Claude Code as a real client; every call
  audited.
- **Accountability layer**: eval-gated promotes (a regressing model is blocked; override goes
  through human approval), auto model cards, EU-AI-Act-framed audit-export packs, weekly AI
  digests, and natural-language database queries that always show their SQL.
- **The signed offline bundle**: images (models inside), charts, docs and a local update channel
  in one openssl-signed, self-verifying artifact; the SEALED ACCEPTANCE WALK is the release gate.
- **Registry fix — `vke-trainer` re-pull required**: the pre-1.3.0 `vke-trainer:latest` manifest
  on ghcr paired one layer with a wrong uncompressed digest (DiffID), so strict runtimes
  (podman/CRI-O on x86 clusters) refused the pull with a "does not match config's DiffID" error.
  The 1.3.0 push replaced the manifest with a corrected, strictly-validated pairing (both
  amd64 and arm64 verified blob-by-blob). **If you hit that error: `docker pull` /
  `podman pull ghcr.io/t4tarzan/vke-trainer:latest` again — no other change needed.**
  (Multi-arch tags are now stitched with `buildx imagetools` so this class of mismatch is
  caught at release time.)

## 1.2.0 · 2026-08-21
- **A real base-model catalog**: Llama 3.2 1B, Gemma 3 1B, SmolLM2 1.7B and Mistral 7B join
  Qwen as trainable bases in every shape. The small trio is BUNDLED — baked into the appliance
  image and pre-fetched at native-mac install — so the training dropdown works fully air-gapped;
  only Mistral 7B downloads on first use.
- **Family-correct serving**: trained-model imports now carry the right chat template per
  base family (ChatML · Llama 3 · Gemma · Mistral), and Gemma bases get their system prompt
  folded automatically (Gemma templates take no system role).
- Trainer image refresh: a GGUF converter with Gemma 3 support plus the engine and logging
  fixes from the native-mac work.
- **Setup** section in the documentation — install instructions for all four shapes — and
  the **/overview** page: the four shapes, the architecture, and the RL-optimized loop.

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
