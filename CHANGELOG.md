# VKE — Changelog

## 1.2.2 · 2026-08-23
- **nomic-embed-text is baked in too**: RAG (backend/factory/rag2.py) defaults VKE_EMBED_MODEL
  to nomic-embed-text and expects it present offline, but 1.2.1's vke-ollama carried only the
  two qwen models — embeddings would have failed on an air-gapped box. The bake now takes its
  model list from one ARG (OLLAMA_MODELS_BAKE) and **asserts a manifest for every model in it**.
  Counting manifests (">= 2") was the weaker check that let a missing third model through.
- **Heads-up on vke-ollama:1.2.0**: that published tag is the zero-model build — its bake layer
  is 0 bytes in the registry (layers 0.03/0.10/0.01/3.23/**0.00** GB vs 1.35 GB here). It is
  left in place for immutability, so anything still pinning `vke-ollama:1.2.0` gets an ollama
  with no models and dead chat. Pin 1.2.2 (or :latest) instead.

## 1.2.1 · 2026-08-23
- **The appliance works on linux/amd64 again**: v1.2.0's `docker compose up -d` came up with
  no models, no dataset list and a fictional cluster on any x86_64 host. Four independent build
  defects, each fixed at its root and each now guarded so it cannot ship again.
- **vke-ollama carries real models**: the bake ran as `pull A && pull B && pkill ollama || true`,
  and a trailing `|| true` applies to the whole `&&` chain — an interrupted pull still exited 0.
  The published image held 941MB of `*-partial-N` chunks and zero manifests; ollama prunes
  partial blobs at startup, so chat and the k8s-sre alias had no model at all. The bake now
  waits for readiness instead of `sleep 5`, runs under `set -e`, stops the server gracefully,
  and asserts real manifests with no partial chunks before the layer may commit.
- **Arch-correct kubectl**: `ARG TARGETARCH=arm64` meant `buildx --platform linux/amd64` still
  expanded to arm64 — BuildKit does not override an ARG that carries a default (verified:
  TARGETARCH=arm64 with uname=x86_64). The amd64 image therefore shipped an arm64 kubectl,
  every cluster probe died with "exec format error", and the console showed the demo snapshot
  as though it were the real cluster. The arch now comes from the image itself
  (`dpkg --print-architecture`), the pin moved to v1.34.11, and the build runs
  `kubectl version --client` so a mismatch fails the build instead of the appliance.
- **No macOS resource forks in the image**: a `.dockerignore` keeps `._*` out of the build
  context at any depth. AppleDouble siblings are git-ignored on a Mac, so release.sh's
  clean-tree gate never saw them and `COPY data/ data/` baked non-UTF-8 `._<name>.jsonl`
  files that made `list_datasets()` raise UnicodeDecodeError — GET /v1/datasets returned 500
  and the Training Studio had nothing to train on. The listing and the seeder skip dotfiles.
- **A working update engine**: watchtower moves to the maintained fork
  (ghcr.io/nicholas-fedor/watchtower, pinned 1.21.0). containrrr has been unmaintained since
  2023 and speaks Docker API 1.25, which every daemon >= 25 rejects, so it crashlooped and
  Settings -> Updates could not work on any current Docker.
- **An artifact gate in release.sh**: after building, each per-arch image is inspected — kubectl
  must actually run, no resource forks may be present, and vke-ollama must carry complete
  model manifests. The old gate only proved the app booted, which all four defects survived.
- **Cluster probes report why they failed** instead of a bare "unreadable / no contexts"
  followed by a silent slide into demo mode.

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
