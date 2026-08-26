# VKE — Changelog

## 1.6.10 · 2026-08-26

**Ask the Database answers on every install.** The tile used to require a configured
read-only dept Postgres and showed an empty screen everywhere else — on a console
sitting on a database full of answerable operational questions. It now offers three
sources: the configured Postgres (unchanged, still the default when present), **VKE's
own database** (incidents · fixes · approvals · usage — read-only, and fenced by a
SQLite authorizer to a safe table allowlist, so generated SQL physically cannot read
users, sessions, keys or settings), and **any uploaded dataset** (the record store
materialised as one in-memory table — SQL over any CSV/JSONL upload with zero setup).

**The SQL writer is pickable.** A tiny domain finetune answers incident questions but
writes poor SQL; the tile now has a model dropdown (plus a `nlsql_model` setting) so a
strong general model writes the SELECT while the receipt still names it.

## 1.6.9 · 2026-08-26

- **Chat had been answering with no retrieval at all, and nothing said so.**
  `rag2.has_content()` ran `SELECT EXISTS(...)` and read `bool(r[0])`. psycopg's
  `dict_row` keys by NAME only while `sqlite3.Row` accepts both, so this passed on the
  appliance's SQLite and raised `KeyError: 0` on every Postgres install — and
  `chat._rag_ground` wrapped the call in `except Exception: pass`, so each answer
  silently lost its grounding. The fifth instance of the bug class fixed in 1.6.7, and
  the first one that failed invisibly. Verified against a live Postgres install: the
  KeyError was the ONLY thing blocking retrieval — with it fixed, "pod stuck Pending on
  the traefik daemonset" grounds to 4.4KB with 4 citations, top hit the exact matching
  signature. The probe is now `SELECT 1 ... LIMIT 1`, which needs no column name on
  either backend, and a grounding failure is logged instead of swallowed.
  Swept the whole backend for positional row access: this was the only real instance.
- **The finetune prompt now matches the serving prompt.** Training stamped
  `factory.data.SYSTEM` while chat sent whatever `model_prompts.json` resolved to — two
  different strings. With `mask_prompt = true` the system turn is pure conditioning, so
  every answer was degraded for no visible reason. `chat.persona_for(alias)` is now the
  single source and `train.prepare()` stamps it onto every row, so the contract holds
  even for an alias with no entry of its own.
- **A known-fixes corpus, because telemetry contains no fixes.** A crashed-pods export
  has a reason and a message but nothing that says what to DO, so training a
  fix-suggester on it can only teach a constant. `fixcorpus` harvests real remediations
  from playbooks, proven KB fixes and approved actions, keyed on signature so a row
  joins the KB, the playbook library and ops-KB retrieval. Gateway distillation writes
  CANDIDATES that are retrievable immediately but never training targets until a human
  signs them off. Exports both ways: signature cards into ops-KB (useful with no
  training at all) and a training view of the verified rows.
- **Answers follow a contract.** The persona now demands Diagnosis / Likely cause /
  Next step / Fence with citations, and a deterministic signature match is layered under
  the semantic hits — an exact `kind:reason:owner` match should never lose to cosine
  distance. Subsumed reason tokens are dropped so an ImagePullBackOff card stops riding
  along on a CrashLoopBackOff question.
- **Training runs report their coverage.** `iters x batch_size` is a hard cap
  independent of dataset size: the default 60 x 2 sees 120 rows, so a 10k-row upload
  trained on 1.2% of itself. `prepare()` now returns coverage and warns in both
  directions — too little, and the memorisation case that made a run's validation loss
  climb 0.233 -> 0.344 while train loss fell to 0.059.
- **Nightly ingestion, threshold-gated retraining.** A new `fix_corpus_sync` job
  harvests and re-ingests every night: cheap, safe, and it improves tomorrow's answers
  with no promotion decision. `auto_retrain` now refuses to run without an eval set to
  gate on, and prefers the fix corpus over raw event history. `evals.seed_from_corpus()`
  builds that set, checking the remediation CLASS so wording may vary but the action may
  not.
- **Datasets keep every column.** An upload now writes two outputs: a record store with
  every source column preserved, and the 2-column training view as a projection of it.
  The CSV path previously read columns 0 and 1 and discarded the rest inside the parser
  — a 7-column export lost 5 columns with no warning and no way back, since the raw
  upload is never kept. Uploads report `columns_used` / `columns_dropped` and refuse to
  pass silently when the target has fewer than 2 distinct values. `rebuild_view()` and
  `query_records()` re-project a different target or a filtered subset without a
  re-upload.
- **Diagnose on an alert now carries context into chat.** app.go() ran the screen
  function without awaiting it, so alertToChat prefilled the input before the chat
  screen had rendered it — the click landed on an empty chat. The context now hands
  off through sessionStorage (question + signature), consumed after the DOM exists.
- **Consensus and distillation honor the Chat gateway URL setting.** consensus_verify
  read VKE_SWITCHBOARD env with a :8000 default, ignoring the "Chat gateway URL (chat +
  consensus)" setting — so pointing chat at Ollama left consensus hammering :8000 until
  timeout. Both now resolve through the one setting, like chat.
- **Fixed alongside:** the PII vault ate Kubernetes names (`dcio-accum-rk-balance-...`
  matched the `sk|pk|rk` secret pattern and became `[SECRET_n]`, destroying the
  service-name signal the module exists to keep); `evals.SWITCHBOARD` was referenced by
  `app.py` but never defined, so the non-alias eval path raised AttributeError; daily
  audit training rows used the report's title line as their summary, teaching the model
  to echo a header; and both the dataset directory and the ops-KB store lived on the
  container's ephemeral overlay, so uploads and ingested runbooks were lost on every
  pod restart.


## 1.6.7 · 2026-08-25

- **Four screens returned 500 on every Postgres-backed install.** All four were SQLite
  idioms the translation shim does not cover, so they worked on the appliance's SQLite and
  failed on DKubeX — where Postgres is the default. Found by probing each feature endpoint
  on a live install rather than by reading code:
  - **Predictive alerts** (`/v1/predict`) used `HAVING n >= 2`, referencing a SELECT alias.
    Postgres requires the aggregate to be repeated: `HAVING COUNT(*) >= 2`.
  - **Analytics** (`/v1/analytics`) grouped by `json_extract(payload,'$.ok')` — a SQLite
    builtin with no Postgres equivalent. The flag is now tallied in Python; the payload is
    already JSON text and outcome rows are few.
  - **Usage summary** (`/v1/usage/summary`) used `SUM(status>=400)`. Postgres has no
    `sum(boolean)`; now an explicit `CASE WHEN`.
  - **Tickets** (`/v1/tickets`) ordered by `id` on the `event` table, which has no such
    column — SQLite silently fell back to its implicit rowid. Ordered by `ts` now, the real
    key.
  Audited the four other `ORDER BY id` sites: those query tables that genuinely declare an
  id column, and are unaffected.


## 1.6.6 · 2026-08-25

- **The Compute picker says whether you are training on CPU or GPU.** It offered only
  "Local — free", so an operator who had moved the trainer onto a GPU node could not tell
  from the UI whether the GPU was being used — which is exactly why the silent CPU fallback
  fixed in 1.6.3 went unnoticed for so long. It now reads "Local CPU — free" or
  "Local GPU: NVIDIA A100-80GB — free", named from the device the trainer reports on
  `/health`, with a line underneath spelling out what that means: slower runs and possible
  refusals on CPU, roughly an order of magnitude faster on GPU. An older trainer that does
  not report a device is treated as CPU.


## 1.6.5 · 2026-08-25

- **Retraining an alias really does continue from the previous run.** "Retrain +data" was
  meant to be v2 on top of v1 and never was: the fused model is written to scratch and
  deleted after import, so it never appeared in the base picker, and every retrain silently
  restarted from the raw base. With the same iteration count on a smaller follow-up dataset,
  v2 could not beat v1. Training now resumes from the alias's saved LoRA adapter. Measured
  with the shipped datasets — `sre-pods-100`, then `sre-pods-append-50` — validation loss goes
  1.347 → **0.069**. The Studio now says, before the spend gate, that a run will continue: it
  usually converges lower and faster, but it keeps the earlier specialisation, and a new alias
  name is the way to train data on its own.
- **Completed runs are no longer dropped from the history.** Runs were deduped by the
  trainer's job id, and that counter restarts at `finetune-1` whenever the forge volume is
  recreated — while the history lives in the database and survives. So after a reinstall every
  new run collided with one recorded by a previous install and vanished. Observed live: a
  freshly trained alias missing from the run list and the overlay, which showed two
  28-hour-old runs instead.
- **The v1 → v2 story reports what the data shows.** Both the Studio overlay and the Iterative
  Demo printed "more data, lower loss" whatever the numbers said — so two runs on the same
  corpus (seeded training, identical curves) were presented as an improvement that had not
  happened. They now report the percentage when it improved, plainly that it did not when it
  got worse, and that there is nothing to compare when both runs used the same corpus.


## 1.6.4 · 2026-08-25

- **A finetune is imported as base + adapter, not a full copy of the model.** Every alias used
  to be a merged 948MB copy for Qwen-0.5B, so ten aliases meant 9.5GB and every retrain
  orphaned another 948MB — which is what actually filled the models volume. The adapter that
  produces the finetune is 4.1MB, and ollama can serve `FROM <base>` + `ADAPTER <lora.gguf>`,
  so the base is imported ONCE under a shared name and each alias is the adapter on top.
  Verified by reading the blob store directly: the alias and the base reference the *same*
  948.10MB blob and the alias adds exactly one 4.14MB blob. Ten aliases go from 9,480MB to
  988MB, and a retrain now orphans 4MB. It also skips the merge entirely, removing the merge
  memory spike and ~6 bytes/param of scratch. `VKE_IMPORT_MODE=merged` restores the old path,
  and any failure falls back to it automatically.
- **The chat alias binds to a model the gateway actually serves.** A reinstall is asymmetric:
  Settings live in Postgres and survive, `served.json` lives on the PVC and does not. So a
  fresh install re-seeded a hardcoded model name that had nothing to do with whichever gateway
  the surviving Settings pointed at — a 404 on the very first message, on an install that
  looked healthy. Seeding now asks the gateway what it serves. An unreachable gateway keeps
  the old behaviour exactly.
- **Point at an ollama you already run** (`ollama.externalUrl`). Chat never needed the in-pod
  ollama, but three things need the ollama API specifically rather than merely an
  OpenAI-compatible one: the trainer's import, the Settings→Models registry pulls, and alias
  promotion. Previously `VKE_OLLAMA` was simply unset when `ollama.enabled=false` and the
  trainer fell back to `ai.baseUrl`, conflating the chat gateway with an ollama server root —
  so the shape worked only when they happened to be the same host.
- **Training estimates tell the truth on a GPU.** `/health` reports the trainer's device, so
  the Studio stops labelling a GPU run "Local — free" with a CPU wall-clock. Measured, that
  gap is 33.5s against 367.6s for the same 60 iterations.
- **The memory gate refitted against a second model.** Fitted on Qwen-0.5B alone it ran up to
  2.2 GiB conservative on Llama-3.2-1B — a deliberately different shape (16 wide layers against
  24 narrow) — which on a small card refuses runs that would fit. Refitted across seven points
  spanning both models; still over-predicts every one, but the margin narrows to 0.12–1.43 GiB.
- **Eviction and payload hardening.** The trainer's memory request goes 1Gi → 3Gi: requests are
  what the kubelet ranks evictions by, and a trainer holding 5Gi against a 1Gi request is the
  first thing evicted under node pressure — surfacing as `Evicted`, which no in-container gate
  can prevent. The inline job payload is bounded at 32MB, since an uploaded dataset has no
  natural bound and a co-located trainer reads the shared claim anyway.
- **The app store advertised roughly half the storage VKE claims** — 31Gi against an actual
  61Gi. Corrected, along with the memory recommendation.


## 1.6.3 · 2026-08-25

- **Training can actually use a GPU.** `train_lora.py` had no device handling at all — no
  `.to(device)`, no `device_map` — so on a GPU node it trained on the CPU silently, the only
  symptom being that it was slow. It now selects cuda > mps > cpu with no configuration,
  moves the model and every batch, and returns the merged model to the host before
  serialising (both `save_pretrained` and the GGUF converter are host-side). Verified on an
  NVIDIA GB10: 60 iterations in 33.5s against 367.6s on CPU, with identical loss convergence
  (1.275 train / 1.337 val vs 1.299 / 1.348), so bf16-on-GPU is numerically equivalent and
  not merely faster.
- **The memory gate understands GPUs.** It previously budgeted the cgroup limit, which is the
  wrong resource on a GPU — a container can have 8Gi of RAM and a 24GB card, or the reverse.
  The budget now comes from the device, and the peak is measured from
  `max_memory_reserved()` rather than `max_memory_allocated()`: the caching allocator holds
  more than it hands out (measured 3.71 GiB reserved against 1.92 allocated on the same run),
  and it is the reserved pool that a further allocation fails against. Coefficients are now
  per-device — the CPU-fitted ones UNDER-predicted GPU peaks by up to 0.8 GiB, the dangerous
  direction, because gradient checkpointing saves far less on a GPU (the seq x vocab logits
  term does not shrink with it).
- **Only 85% of free VRAM is offered as budget.** On unified-memory parts (Grace-Blackwell,
  Jetson) device memory IS host memory, so a run that claims all of it starves the host and
  can wedge the machine rather than failing inside the container — observed directly on a
  GB10. For the same reason the gate stays predictive and never attempts-and-recovers: a CUDA
  OOM is not reliably a catchable exception there.
- **A CUDA trainer image** (`Dockerfile.cuda`). Two things differ from the CPU build and both
  matter: torch comes from the default index rather than the cpu-pinned one, and `gcc` +
  `libc6-dev` are installed because Triton JIT-compiles a shim against `Python.h` on the
  first CUDA kernel — without a compiler a GPU run dies on the FIRST TRAINING STEP, after the
  model has loaded onto the device. The CPU image never installs Triton, which is why no
  amount of CPU testing surfaces this.
- **The trainer can be its own Deployment** (`trainer.split`). A GPU belongs to the trainer,
  not the UI: as a sidecar the whole pod must be scheduled onto the GPU node, so an idle web
  UI and an ollama occupy capacity billed at GPU rates. Split, only the trainer lands there.
  This is possible because the app now posts the job spec and dataset INLINE, so the trainer
  no longer needs to share VKE's forge volume — without that, splitting would require an RWX
  StorageClass, since the models claim is ReadWriteOnce.
- **GPU wiring that actually works.** Being on a GPU node is not enough: the device plugin
  injects devices only when the container requests `nvidia.com/gpu`, and GPU node groups are
  conventionally tainted, so without tolerations the pod never lands there. Both are wired,
  with an optional `runtimeClassName` for clusters that route GPUs through containerd
  handlers. `trainer.gpu.enabled` without `trainer.split` now FAILS the render instead of
  silently producing a CPU-image sidecar with no GPU request.
- **The GGUF converter path is no longer hardcoded** to `/app`, so the trainer can run outside
  its own container layout.


## 1.6.2 · 2026-08-25

- **Every bundled base can actually be fine-tuned now.** `train_lora.py` loaded the base in
  fp32, which put all four bundled bases over the trainer's memory limit at the shipped
  `max_seq_length=1024` — measured, the picker was offering three bases that could never
  finish and one that only survived because the seeded SRE rows are short (~260 tokens). The
  base now loads in bf16 with `low_cpu_mem_usage`, and gradient checkpointing switches on
  when the run needs it. Measured peaks at seq 1024: Qwen-0.5B 2.0 GiB · gemma-1b 3.2 GiB ·
  Llama-1B 4.3 GiB · SmolLM2-1.7B 5.4 GiB, all previously OOMKills. bf16 also proved ~28%
  FASTER than fp32 on CPU here, so this costs nothing at the shipped sequence length.
- **A run that cannot fit is refused, not OOM-killed.** The trainer now reads its own cgroup
  limit and estimates the peak from the base's real architecture (params, layers, hidden,
  vocab) and the sequence length, plus the free space the fuse needs. Over budget, it
  refuses up front and names a `max_seq_length` that would fit. An OOMKill loses the log,
  restarts the container and leaves the job unrecoverable, so it must never be the way a
  client discovers a run was too big. The estimate is fitted to measured runs and biased to
  over-predict.
- **Two training runs can no longer collide.** `POST /jobs` refuses while a run is in
  flight. Two concurrent runs each load their own copy of the base, so the pair exceeds any
  limit one run fits in — this is what killed the `ft1` run.
- **A restarted trainer no longer loses a run forever.** The job registry lived only in the
  process's memory, so after a restart every id answered `"unknown"`, which is not terminal:
  the Studio polled a dead job indefinitely. State is now on the models volume, and a run
  whose process vanished reports `failed` with the reason.
- **Superseded model weights are reclaimed.** Ollama never garbage-collects: re-importing an
  alias rewrites its manifest and orphans the previous weights (measured 948 MB per
  Qwen-0.5B retrain), so retraining — and the nightly auto-retrain especially — filled the
  models volume. Unreferenced blobs are now swept after each import, and fuse scratch is
  cleaned on the failure paths too, not only on success.
- **Ollama sized to what it actually serves.** Serving one 2.2 GB model measured 3.99 GiB
  against a 4 GiB limit. The limit is now 8 GiB, with `OLLAMA_MAX_LOADED_MODELS=1` so it
  cannot stack a second model inside it. The trainer limit goes 6 → 8 GiB and the models
  volume 30 → 60 GiB, which holds ten trained aliases of any bundled base.
- **The Studio stops lying about a failed run.** A new launch no longer leaves the previous
  run's loss curve on screen under the new job's name (`ft1` displayed `k8s-sre`'s curve),
  polling gives up on an unrecoverable run instead of spinning forever, and a refused launch
  says why.


## 1.6.1 · 2026-08-25

- **The evals path follows the Settings gateway.** `backend/evals.py` captured
  `VKE_SWITCHBOARD` at import and used it as the fallback in `_target_base()`, so an
  operator who changed the chat gateway on the Settings page would not move evals until the
  pod restarted — the same bug fixed for `chat.py` and `factory/train.py` in 1.3.5, missed
  because this file arrived with the t4tarzan merge. A per-alias endpoint still takes
  precedence, as before.
- **The finetune path stops misrepresenting its endpoint.** `factory/train.py` carried a
  module-level `FOUNDRY` constant that nothing read; it made the Foundry endpoint look
  env-only and import-frozen when in fact both calls resolve `llm_auth.foundry()` per
  request, so a Settings edit applies immediately. Removed, with a note pointing at the real
  resolution site. Launch failures now name the endpoint too — a connection error carries no
  URL, so a mistyped Foundry URL used to produce a bare "connection refused".
- **One source of truth for the forge directory.** `status_flow()` looked for adapters under
  `VKE_FORGE` defaulting to `/forge`, while `prepare()` writes under the module `FORGE`,
  which defaults to `~/hub2/projects/forge`. On a box with `VKE_FORGE` unset the two
  disagreed. Latent in-cluster, where both are `/forge`.

## 1.6.0 · 2026-08-24

- **The two lines merge.** This release joins the `t4tarzan` trunk (the air-gap arc 1.3.0,
  the everything-clickable enhancement release 1.4.0, and the Learn-mode flywheel 1.5.0)
  with the DKubeX line that ran from 1.3.0-dkubex through 1.3.8. Both histories are kept
  below; nothing was dropped. The version is above both so no install can be confused about
  which is newer.
- **What the DKubeX line brings** (detailed in the 1.3.x entries below): Postgres support
  and base-path routing for the platform; SecureLLM's internal `x-token` service-to-service
  auth with every gateway call authenticated, not just chat; gateway endpoints that are live
  and switchable from Settings instead of captured at import; the model hub, which pulls
  models from an OCI registry into the bundled Ollama for sites that cannot reach Hugging
  Face; a trained alias that no longer reports another model's backing; and readable gateway
  errors in place of a bare `KeyError`.
- **Kept from the trunk on merge**: the pooled upstream client and off-loop request
  preparation in `/api/v1`, the served-registry read cache, alias version/promote stamps,
  incident-context chat events, and the new test suite.

## 1.5.0 · 2026-08-24
- **Known fixes come first**: when an alert fires on a problem this cluster has already fixed
  successfully, the hourly sweep now proposes that PROVEN fix straight into the Approvals queue —
  before any model suggestion. One pending proposal per problem signature; nothing executes without
  a human approval; graduated fixes still auto-apply under T0. Toggle: Settings → "Known fixes first".
- **Nightly auto-retrain from the logs (opt-in)**: the platform's own event log is its training
  corpus — with the new Settings toggle on, a nightly job retrains the k8s-sre model whenever the
  corpus has grown by ten or more rows. The result is a CANDIDATE only: the evaluation gate and the
  human promote step stay exactly as they were. Off by default.
- **A worked, verified fine-tuning walkthrough** (docs/USECASE-append-retrain.md): upload a small
  case dataset, train, append more facts, retrain FROM the fused first version — the starting loss
  drops (the weights carry over), validation improves, and the model answers every taught fact
  verbatim while honestly failing what it was never taught. The Iterative Demo tile now shows this
  real before/after pair.

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

## 1.3.8 · 2026-08-24
- **Settings page loads again.** 1.3.7 shipped the Models card declared ABOVE the `row()`
  helper it calls. Template literals evaluate eagerly and `const` is not hoisted, so
  rendering hit `row` in its temporal dead zone: `ReferenceError: Cannot access 'row'
  before initialization` aborted `screenSettings()` and the page came up blank while every
  other page was fine. `node --check` cannot catch this — it is a runtime error in valid
  syntax — so `bin/render-settings-check.js` now executes the screen against stubs and
  asserts the cards render. It fails on 1.3.7 and passes here.

## 1.3.7 · 2026-08-24

- **Pull models from an OCI registry after deployment (Settings -> Models).** The bundled
  ollama image carries only two small qwen models, and a sealed site cannot reach Hugging
  Face -- but it can usually reach a registry. Discover what is available, pull with live
  progress, and the model becomes a real Ollama model that appears in the Converse
  dropdown. Weights stream registry -> Ollama, so nothing is staged on disk in transit;
  only the final copy in the ollama store costs space. Needs no `oras` and no ollama CLI.
- **The registry is configurable, and switchable at runtime.** `modelHub.registry` in
  values, editable on the Settings page like the gateway fields, so a site can retarget
  to an intranet mirror without a rollout. The private-package PAT stays Secret-backed --
  the settings payload reaches a browser, so it reports only whether one is configured.
- **Discovery reads a catalogue artifact, because a registry cannot be listed.** GHCR
  answers 403 to `/v2/_catalog`, and the GitHub Packages API needs egress a sealed site
  does not have. `bin/ollama-ghcr.sh index` runs where there IS internet, enumerates the
  namespace, keeps only real ollama model artifacts, and publishes the catalogue beside
  the models. It warns when the result is not readable anonymously -- a new GHCR package
  is private by default and there is no API to change container visibility.
- **A container image can no longer be mistaken for a model.** Registry namespaces hold
  both, and a plain image has no `artifactType`, so it slipped a too-tolerant guard and
  the largest-layer fallback selected a 3GB docker tarball as if it were weights. A
  missing `artifactType` is now accepted only alongside a real weight layer.

## 1.3.6 · 2026-08-24

- **The gateway auth default now matches the gateway URL.** 1.3.5 seeded the new "Chat
  gateway auth" setting from a fallback that assumed `bearer`, so a fresh install showed
  `bearer — Authorization: Bearer` directly above a bundled-Ollama URL that needs no auth —
  contradicting the field's own "must match the URL above" hint. The scheme is derived from
  the deployment now: no key injected means `none`, a key means `bearer`, and
  `securellm.internal` means `k8s-sa`. Behaviour is unchanged either way (bearer with an
  empty key already sent no header), but the value shown is true. Installs carrying the
  wrong seeded `bearer` are repaired on boot; any deliberate choice — including `bearer`
  with a real key — is left untouched.

## 1.3.5 · 2026-08-24

- **The Settings page's gateway fields actually work now.** "Switchboard URL" and "Foundry
  URL" have always been on the Settings page and have always saved — but nothing read them:
  `chat.py` and `factory/train.py` each captured `VKE_SWITCHBOARD` / `VKE_FOUNDRY` into a
  module constant at import, so an edit changed a value no code ever consulted. Both are
  resolved per request now (`backend/llm_auth.py`), Settings winning over the env, so you
  can move chat between the bundled Ollama, SecureLLM and any other OpenAI-compatible
  endpoint from the UI with no rollout.
- **Auth is switchable with the URL.** A URL change alone is not enough: in-cluster
  SecureLLM rejects `Authorization: Bearer` with 401 while Ollama wants no header at all. A
  new "Chat gateway auth" selector picks `none` · `bearer` · `k8s-sa` and takes effect on the
  next request. Verified live — flipping to `bearer` against SecureLLM makes its model
  vanish from the dropdown, flipping back restores it.
- **Settings no longer displays a fiction.** Those fields were seeded to `127.0.0.1:8000` /
  `:9003` and shown unchanged on every in-cluster install. On boot VKE now adopts the
  endpoints the deployment actually injected — but only when the stored value is still that
  untouched seed default, so an operator's own edit is never overwritten. Without that
  guard, honouring the setting would have repointed every existing install at localhost.
- **The finetune endpoint is live too**, so the Foundry URL can move without a redeploy.

## 1.3.4 · 2026-08-24

- **SecureLLM internal service-to-service auth (dkubeio/vke#1).** In-cluster SecureLLM does
  not accept `Authorization: Bearer` — it wants the caller's ServiceAccount token in
  `x-token` plus `x-requested-user`. Verified against a live SecureLLM: `x-token` → 200,
  Bearer with the same token → 401, no auth → 401. Enable with
  `--set securellm.internal=true`; unset keeps the Bearer behaviour exactly as before.
  The SA token is re-read on every request because the kubelet rotates it — a value cached
  at import works right after a rollout and then 401s for the rest of the pod's life.
- **Every gateway call now authenticates, not just chat.** Outbound auth moved into one
  module (`backend/llm_auth.py`). `gateway.py`'s four upstream calls (streaming and
  non-streaming completions, embeddings, the retry path), `factory/serve.py`'s promote
  probe, `factory/bench.py`'s scoring and `factory/rag2.py`'s embeddings all sent NO auth
  header, so against any authenticated gateway they simply failed.
- **A gateway error is readable now.** Any upstream rejection collapsed into
  `gateway: 'choices'` — a bare `KeyError` from indexing an error body — which is what the
  Studio showed when Test was pressed. You get `gateway 400: model is required` instead.
- **Chat no longer answers with silence on a gateway error.** `stream()` only forwarded
  lines starting with `data:`, so a non-200 error body matched nothing and the turn ended
  empty. It now surfaces the status and message.
- **Test on an unpromoted alias says what to do.** A recorded candidate does not back the
  alias (the Track B→A gate), so Test dispatched `model: null`. It now reads "press Promote
  to serve the candidate (<name>)" instead of failing obscurely.
- **Forge jobs record a base path that exists.** `MODELS_DIR` was hardcoded to
  `~/hub2/models`, so in-container it wrote `base = "/root/hub2/models/<name>"` into the
  job config — a directory present nowhere in the pod. It survived only because
  `train_lora.py` takes `basename()` and re-resolves. Now honours `VKE_MODELS_DIR`, which
  the chart points at `models.basesPath`.

## 1.3.3.1 · 2026-08-24
- **Chart 0.2.2 pins `image.tag`** to an immutable release tag instead of `latest`.
  `latest` is mutable while `pullPolicy` is `IfNotPresent`, so a node that had already
  cached an older `latest` never re-pulled it and silently kept serving the old app
  through installs and restarts — and the DKubeX app store cannot pass
  `--set image.pullPolicy=Always`, so the tag itself has to move each release.

## 1.3.3 · 2026-08-24

- **A freshly-trained alias no longer reports someone else's model.** `record_candidate()`
  created a new alias by copying `k8s-sre`'s config, so `train1` came up claiming
  `backing mistral-small-24b` on the **cloud** track — a model that alias never had, and
  a track it was never trained on. New aliases now start with no live backing (nothing
  backs them until the candidate is PROMOTED — the Track B→A gate) on the local track.
  The same shallow copy also shared `DEFAULT_SERVED`'s `history` list, so alias history
  leaked into the module default and into every alias created afterwards.
- **`Set default` actually moves the chat default now.** The button wrote the
  `chat_default_model` config key while the §5 "chat default" pill compared against
  `served.json["default"]`, so clicking it could never change what you saw. Both
  `/v1/serve/set-default` routes now also move the served-registry default when the
  target is an alias.
- **The Training Studio stops describing a Mac.** In-cluster there is no MLX and no
  `~/hub2`: Compute read "Local MLX — free", §1 claimed "Every MLX model on this box",
  and a finished run pointed at `~/hub2/models/<job>` — a path that does not exist in the
  container. The fused model is imported into Ollama; the trainer's own log said
  `/models/<job>`, which is never written either. All four now tell the truth.
- **Candidate recording no longer hangs off a wrong path.** `status_flow()` detected a
  finished fuse with `"/models/" in log and "fused model" in log`, so correcting that log
  line would have silently stopped candidates being recorded and made Promote vanish. The
  detector now keys on `"fused model"` alone and matches old and new trainer images alike.
- **Chart: one volume for the models claim, so installs stop logging a scheduling
  failure.** `<release>-models` was declared TWICE in the pod (as `forge` and `models`,
  the same claim). Naming one PVC twice makes the scheduler's VolumeBinding PreBind patch
  it twice in a single pass; the second write carries a superseded resourceVersion, so
  every install logged `FailedScheduling ... "vke-models": the object has been modified`
  before retrying. One volume, several subPaths — every mountPath unchanged, no migration.
- **Chart: the AI model matches the AI endpoint.** `ai.baseUrl` moved to the bundled
  in-pod Ollama but `ai.model`/`ai.track` still said `dkubex/qwen3-6-27b` / `cloud` — a
  model that endpoint has never served. Since `_twin_defaults()` injects `ai.model` as
  both `chat_default_model` and the `k8s-sre` binding, the default chat model and the
  alias both answered nothing. Now `qwen2.5:1.5b` / `local`.
- **Chart: `ollama.tag` pinned to 1.2.2** rather than the mutable `latest`, so a
  reinstall can't silently land on a different model set.

## 1.3.2 · 2026-08-23
- **Chat works again, and trained models actually answer.** Two bugs, both making chat
  return an empty `…`. `ai.baseUrl` ended in `/v1` while `chat.py` appends its own, so
  every request went to `/openai/v1/v1/...` and 404'd — silently, because the model list
  swallows the error and falls back to showing only the factory aliases. And
  `serve.promote()` looked for the freshly-trained model on the chat gateway, when
  `ollama create` had imported it into the bundled in-pod Ollama; the alias never got
  repointed. promote() now finds it there and records a per-alias endpoint, which
  `chat._route()` already honours, so a promoted finetune is served by the bundled
  Ollama while general chat stays on your gateway.

## 1.3.1 · 2026-08-23
- **Postgres boot fix**: with `postgres.db_url` set, `init()` crashed before the app came
  up — `psycopg.errors.SyntaxError: syntax error at end of input`. Two causes, both now
  fixed. The script splitter only stripped WHOLE-LINE `--` comments, so the semicolon in
  `rag_chunk`'s trailing comment (`-- float32 le; source of truth`) split that CREATE
  TABLE mid-comment and handed Postgres an unterminated statement; it now strips `--` to
  end-of-line and ignores both comments and semicolons inside quoted literals. And
  `_pg_ddl` had no mapping for SQLite's `BLOB`, which Postgres has no type for, so
  `rag_chunk.embedding` failed with `type "blob" does not exist` and every later
  statement against that table cascaded; it now becomes `BYTEA`.
  Verified against a real PostgreSQL 15: all 25 statements apply, 20 tables created,
  `init()` completes, and a float32 `bytes` value round-trips through the embedding
  column. SQLite installs were never affected — `sqlite3.executescript` parses comments
  itself, which is why this only showed up on DKubeX.

## 1.3.0-dkubex · 2026-08-23   (the DKubeX line; renumbered on merge — t4tarzan shipped a different 1.3.0, below)
- **The appliance triple, in your cluster**: the Helm chart's pod now runs `vke` +
  `vke-trainer` + `vke-ollama` together, the same self-contained shape docker-compose has
  always had. `ollama.enabled` and `trainer.enabled` both default ON — the published images
  are multi-arch (linux/amd64 + linux/arm64) now, so the old arm64-only caveat is gone.
- **Training actually finishes in-cluster**: the trainer's `OLLAMA_HOST` pointed at
  `ai.baseUrl`, an OpenAI-compatible `/v1` gateway the `ollama create` CLI cannot talk to,
  so every in-cluster run died at the final import step. It now points at the bundled
  server in the pod. Chat is untouched and still uses `ai.baseUrl`.
- **Models and training scratch survive a restart**: one shared `<release>-models` volume
  (30Gi default) holds the trainer's base weights, the ollama model store and the forge
  scratch, in `bases/` · `ollama/` · `forge/` subpaths. `/forge` was an emptyDir, which put
  multi-GB merges on node ephemeral storage and could get the whole pod evicted mid-train.
  The vLLM tier shares the same volume, so a base seeded once serves every tier.
- **Baked models are seeded, not masked**: mounting a volume over a baked model directory
  makes it start EMPTY — a Docker named volume seeds itself from the image, a k8s volume
  never does. Two initContainers copy the baked ollama store and the ~9GB of HF bases onto
  the volume on first start, and fail loudly rather than booting an empty chat. This is the
  "bundle installer" the vLLM values comment always referred to. First start takes several
  minutes; `progressDeadlineSeconds` and the chart timeout were raised to match.
- App storage (`storage.size`, 1Gi) is deliberately unchanged: a bound PVC only resizes on a
  StorageClass with `allowVolumeExpansion`, so growing it would break `helm upgrade`.
  Chart 0.2.0.

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
