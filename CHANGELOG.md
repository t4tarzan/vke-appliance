# VKE — Changelog

## 1.6.43 · 2026-09-02

- **The model card now tells the truth about loss.** A card could read `0.003 → 0`, which is
  two separate lies about a healthy run. (1) The run history stores losses as a 60-point
  *window*, so on a 200-iteration run `losses[0]` was iteration ~141 — a converged mid-run
  value presented as "the starting loss". The true first train/val values are now recorded
  before the window is taken, and pre-existing entries are labelled *"oldest kept point, not
  the run start"* rather than silently misreported. (2) The trainer logged loss at `.3f` and
  the studio parses those log lines back into history, so anything under 0.0005 became exactly
  `0.0`; loss is now logged at `.5f`, and a floored value renders as `<0.00001 — not zero`.
- **Validation loss is on the card.** It was recorded all along and never shown, which is
  precisely what made a near-zero train loss look alarming. The held-out signal now has its
  own row, marked as the one to read.
- **Fixed: every run in the training chain reported `val: null`.** The curriculum record read
  `val_loss` off the history entry — a key the writer has never produced. It now reads from
  `val_losses`/`metrics`, so continue-training (train an alias again on new data) finally shows
  its per-run validation descent.
- **The chat picker no longer lists a trained model twice with no explanation.** A fused run
  publishes weights as `<alias>:latest`, so the switchboard listed the bare artifact alongside
  the alias — same weights, two entries, only one carrying a model card. The bare entry is kept
  (an unpromoted candidate is the only way to chat with weights the alias is not serving) and
  is now labelled *raw weights of* / *unpromoted candidate of* its alias. Matching is confined
  to the `<alias>:latest` fuse namespace, so an alias backed by a base model never relabels or
  hides that base model.
- **Fixed the projection bug that trained a classifier instead of an assistant.** A crashed-pods
  upload carrying both `solution` (1000 distinct written fixes) and `reason` (5 event labels)
  trained on `reason` — with `solution` left sitting in the *input*. The adapter learned to emit
  one of five words. Cause: `_TARGET_NAMES` listed `resolution` but not `solution`, and the picker
  scanned columns in reverse-alphabetical order, so the choice came down to alphabetical position.
  Target columns are now **ranked** — a written answer always outranks a label — and `solution` is
  in the list. Unchanged for any dataset with a single candidate column.
- **The question side can no longer contain the answer.** `render_query` now excludes target
  columns unconditionally, so a stale or hand-written `context` cannot leak the label.
- **The degenerate-target guardrail actually fires.** It only warned at "fewer than 2 distinct
  answers", which this dataset (5 distinct, ~7 characters, 1000 rows) sailed past. It now also
  flags a **label-shaped** target — few distinct values for the row count *and* very short answers
  — and names the written-answer column that was passed over.
- **A training target may now be several columns** (`target=["reason","solution"]`), rendering
  `Reason: <label>` followed by the prose. The label is scoreable on a held-out split and can be
  checked against the live event reason at inference; a string target is unaffected.
- **The chat answer no longer invents a Kubernetes object out of the question.** "Assess the
  overall health…" produced *"no failing pod matches 'overall'"* — the first non-stopword token was
  treated as a resource name. Tokens are now punctuation-stripped before the stopword test (which
  is why `now.` also slipped through), generic-intent words are stopwords, and the "no pod matches"
  line requires a resource-shaped name. A general question about a healthy cluster now gets a
  plain cluster-wide finding instead of no finding at all.
- **Fixed JS leaking into the chat card as visible text.** `screens3.js` dropped `JSON.stringify`
  output raw into an `onclick` attribute; its quotes closed the attribute and the `>` in a fix
  text's `<pod>` placeholder closed the tag, so `",channel:'chat'})">` rendered next to the Propose
  button. Every other call site already escaped this.
- **Truncated text no longer cuts mid-word** — the card showed a cause ending "it als". Clipping is
  word-boundary aware with an ellipsis.
- New `tests/data_target_walk.py` pins the whole projection chain.

## 1.6.42 · 2026-09-01

- **Documentation release.** The public docs (vke.dkube.app · vkedgx · the GitHub-Pages copy) are
  brought fully current: the install matrix for every shape (native macOS/MLX · appliance compose
  amd64+arm64 · in-cluster Helm, now `--version`-current · the signed air-gap bundle, with the
  Compose-v2 requirement and fix), and the features shipped across 1.6.34–1.6.41 — three-section
  cited answers with the 0–100 confidence meter, day-one knowledge (12 runbooks · 14 verified
  corpus rows · the 40-card K8s Field Guide), the fix-corpus Verify panel, Ask the Database,
  bundled starter datasets, eval-gated promote, and the Training Studio's continue-training /
  lineage lock / curriculum runner. Plus a new **"How VKE learns — day one to autonomous"**
  section: the four compounding loops, the honest maturity map, and the operating cadence.
  No behavior changes.

## 1.6.41 · 2026-09-01

- Bundled fix-knowledge now seeds at BOOT (idempotent) — an upgraded install no longer waits
  up to 24h (the nightly sync) for newly bundled rows; fresh installs unchanged.

## 1.6.40 · 2026-09-01

- **Field-verified knowledge promoted to the bundle.** The `pod:UnexpectedAdmissionError`
  fix (GPU/extended-resource admission failure — the unit already held, or the device plugin
  re-registering after a node restart) joins the bundled fix corpus as row 14, verified from
  boot on every install. It earned its place the product's own way in one day: surfaced as a
  knowledge gap → distilled → corrected against the real cause → human-verified on a live
  cluster. The generator gained an AUTHORED section for exactly this promotion path; training
  dataset and sanitization unchanged (zero-leak sweep clean).

## 1.6.39 · 2026-09-01

- **The training lineage layer (five extensions, answer path untouched).** ① **Lineage lock**
  — an existing run chain pins its base: retrains default to it (auto_retrain included), and a
  base change is refused loudly (`lineage_locked`) unless `override_base` is explicit — a resume
  on the wrong base corrupted silently before. ② **Continue-training is visible**: the Studio's
  §1 lists existing models ("continue: k8s-sre · 5 runs · resumes · trained through: a → b"),
  picking one locks job+base together. ③ **The curriculum runner**: "＋ stage" on any dataset
  builds an ordered chain trained as SEQUENTIAL RESUME RUNS on one job (launch validates every
  stage; a watcher advances on success; §4 shows "stage x/y"; the run history is the curriculum's
  own record). Proven live: a 2-stage chain ran unattended, stage 2 resumed the stage-1 adapter.
  ④ **Model-card clarity**: an explicit "serving X — NOT the last trained model" banner when the
  backing differs from the trained candidate, a Training-chain section (oldest→newest), and
  promote history labeled (old → new). ⑤ **The eval gate armed from boot**: fresh installs seed
  the k8s-sre exam from the bundled verified fix corpus, so promotes are gated everywhere.
- rag2 field-guide seeding fixed (collection shape) — 40 guide docs land in the semantic lane
  at boot where embeddings exist.
- **Knowledge-surfaces audit (operator ask):** the fix corpus — what chat actually retrieves as
  "Known fixes" — had NO screen and no way to sign off a distilled candidate. The Knowledge Base
  tile now carries a **Fix corpus panel**: every row with signature · provenance · verified/candidate
  state, one-click **✓ Verify / Unverify** (sre_lead/ml_engineer — the gate that turns a candidate
  into a training target), full-text drawers, corpus KPIs, and two tools (**Export corpus → dataset**,
  **Push corpus → Knowledge**). The Knowledge tile's semantic search now reports an embeddings-down
  state honestly instead of "no hits". Fixed a real seeding bug the audit caught: the field-guide
  rag collection re-ingested on every boot (160 docs for 40 cards, duplicate hits) — seeding is now
  fingerprint-gated and replaces instead of accumulating.

## 1.6.38 · 2026-09-01

- **The K8s Field Guide — bundled generic operational knowledge.** 40 authored,
  synthetic-but-technically-true cards (`data/field-guide.jsonl`, generator
  `bin/gen-field-guide.py`) covering restarts/rollouts, scaling, scheduling & node selection,
  namespace/port/DNS/ingress wiring, RBAC & access increments, storage, probes & sizing — each
  fence-aware. Consumed three ways from one file: a DETERMINISTIC retrieval lane
  (`backend/kbguide.py`, works on every shape incl. sealed/no-embeddings installs), a rag2
  semantic collection where embeddings exist (boot-seeded, fail-soft), and the
  **field-guide-qa dataset** (99 Q/A rows + refusals) in the Studio picker — whose card records
  store is queryable through **Ask the Database**.
- **§②/§③ enhanced, not restructured:** §② gains a "📚 from the field guide" block; §③'s
  assessment gains Supported-by and — when no cluster fix exists yet — a clearly-labeled
  generic recommended fix from the guide, so the agent reasons instead of drying up. Guide
  support earns +8 confidence, deliberately below any cluster-verified weight.
- **Default sre-history training runs now fold the guide in** (99 rows at prepare-time;
  the corpus-growth counter still measures real history only) — the cluster's own incidents
  teach the facts, the guide teaches the causal reasoning.
- **Native trainer now RESUMES like the container one:** forge passes
  `--resume-adapter-file` when a job's adapter exists — the Studio's `resumes: true` estimate
  was already promising v2-on-v1 continuation; the native MLX path now honors it.
- Question stop-words extended (no more "no failing pod matches 'happened'").
- **Efficacy proven, multi-iteration (the reinforcement-style requirement):** a held-out
  10-question exam (paraphrases, none in training) against Qwen2.5-0.5B — base **0.30** →
  after one field-guide-qa run **0.50** → after a SECOND run of the same job (adapter
  RESUMED, weights carried: train loss started at 0.028 not ~3.5, val 1.013→0.978) **0.80**.
  Monotonic. `bin/guide-efficacy.py` reproduces it end-to-end through the product's own
  launch flow.

## 1.6.37 · 2026-09-01

- **Open reason vocabulary for fix retrieval.** `signals_in`'s reason list was a closed tuple, so a
  row distilled for a NOVEL failure reason (live case: `UnexpectedAdmissionError` on the DGX) could
  never be retrieved — distill-from-a-gap wrote rows the lookup was structurally blind to. The
  corpus's own signatures now extend the vocabulary, so a distilled row becomes retrievable the
  moment it lands. Subsumed-token dropping + the static floor unchanged; regression-checked.
- **Trainer floating tags repaired + versioned.** `vke-trainer:latest` was silently serving
  1.6.28 content — the 1.6.30 tag-move never held on the registry — so the signed bundles
  1.6.31–1.6.36 carried a trainer without the Mistral answer-span fix (qwen/granite training
  unaffected; only Mistral finetunes in those sealed installs are impacted — retrain on this
  bundle's trainer). `latest`/`lean` now serve trainer-HEAD content, `1.6.37`/`1.6.37-lean`
  pin it, and release pre-flight gained a floating-tag coherence check so staleness can never
  pass unnoticed again.

## 1.6.36 · 2026-09-01

- **The three-section trained-model answer, rebuilt for readability + reasoning.** Section ① now
  renders chat-JSONL training rows as `incident → fix` pairs instead of the raw row repr. Section ②
  is fully structured: cluster-pulse chips, failing-pod rows with the question's own workloads
  flagged, recent warnings, and learned-fix cards carrying signature · ✓ verified · success stats ·
  fence. Section ③ opens with a deterministic ASSESSMENT scaffold — numeric confidence meter,
  Finding, Likely cause, a Recommended-fix box with a one-click ⚡ Propose (routes into the fenced
  approval flow), alternate causes from the playbook library, and an explicit next step — with the
  model's prose streaming beneath it under an answer contract that forbids the ask-back failure mode.
- **The reason bridge.** A layman question ("minio is throwing errors") carries no k8s failure token,
  so the signature lookup used to dry up while the live cluster was showing the reason. Grounding,
  citations, the verdict and the assessment now share an evidence-augmented question carrying the
  matched (else top) live problem's observed reason + name.
- **Fix-corpus ranking fix.** Name tokens now join on the signature's OWNER segment only — the plain
  word "health" in "assess health" was substring-matching `pod:Unhealthy`'s reason and outranking an
  exact Evicted signal. The crashy/traefik owner joins (D5.8) regression-checked intact.

## 1.6.35 · 2026-09-01

- **VKE now ships knowing the ten canonical Kubernetes failures.** A real fixed-incidents
  corpus (3,300 EKS pod-crash events with their working solutions) was distilled into the
  product: the builtin playbook library grew 4 → 12 deep runbooks (startup/readiness/liveness
  probes split and explained, evictions as capacity decisions, config/dependency crash-loops,
  overload-vs-deadlock, image-pull as a config fault), and a bundled `data/fix-knowledge.jsonl`
  seeds 13 curated, verified fix-corpus rows on every fresh install — so chat with cluster
  context answers the common failures WITH citations from day one, before the cluster has any
  history of its own. All identifiers sanitized; `bin/gen-fixes-knowledge.py` regenerates
  everything deterministically from the private source.
- **A new always-there training dataset: `fixes-log-120`.** 120 rows in the serving-contract
  shape — 100 worked examples (context brief → Diagnosis/Likely cause/Next step/Fence, balanced
  across 8 crash categories with per-root-cause diversity), 14 refusal rows (calibrated
  "no verified fix — investigate via X" honesty), and 6 hard-negative pairs (near-miss
  signatures with DIFFERENT correct verbs: ImagePullBackOff vs CrashLoop, OOM vs Evicted,
  readiness vs startup probes). Ships with a 1,088-row sanitized records store, so Ask the
  Database works on the same events the model trains on.
- **Every answer now carries a numeric confidence score (0–100), and the scores are kept.**
  Deterministic: a verified fix-match, the fix-class's REAL success rate, retrieval strength,
  the replay-verified bonus and source corroboration add up; conflicting sources cap it. The
  high/medium/low band now follows the score (a one-weak-citation answer reads low instead of
  hiding behind "grounded"), and every scored answer lands in `answer_score` — the daily
  average is the model's maturity signal.
- **The eval exam grows itself.** Every approved fix whose outcome came back OK harvests an
  eval case (incident context → the known-good fenced verb; `auto-harvest` set, capped 3 per
  signature). The eval-gated promote and nightly auto-retrain now judge candidates against the
  cluster's own resolved incidents — the gate stops starving on day one.
- **Dry-ups become work items.** A low-confidence answer records its question in the
  knowledge-gap ledger (deduped, counted). The Flywheel board lists the top gaps with
  one-click Distill (targeted; the result is an unverified candidate for review) or Dismiss —
  the model's ignorance produces its own curriculum.
- **The learning curve is on the Flywheel board.** Coverage (failure classes seen with a
  verified fix ÷ classes seen), the 14-day confidence trend, the exam size, open gaps — and a
  projection: at the trailing verification rate, the estimated weeks to 80% coverage.
  The methodology (day-0 → steady-state maturity map, operating cadence, why confidence buys
  proposals and only verification buys autonomy) is in `docs/LEARNING-LOOP.md`.
- The fixes-log corpus also gained a **real-names private twin** (`data/private-datasets/`,
  never in public images) — on the operator's own installs, analytics/watchlist/proposals
  ground on the actual namespaces and workloads.

## 1.6.33 · 2026-09-01

- **The Autonomy Board's row controls stop dwarfing the row.** enable T0, the breaker
  select, Replay-verify and Delete were a four-deep right-hand stack taller than the
  fix-class they belong to. They are a two-column grid now — enable T0 and breaker on one
  line, Replay-verify and Delete beneath — collapsing to one column on narrow screens.
- **Nothing on that page depends on a browser dialog any more.** Rebuild used `confirm()`,
  which is unstyled, blocks the tab, and cannot show what the preview actually says. It now
  reads the chain, renders the preview in place — outcomes counted, classes to create and
  update, and the warning that consent and replay-verification are not restored — and
  offers Cancel / Rebuild now inline. Delete asks in the row the same way, and issues no
  request until it is confirmed.

## 1.6.32 · 2026-08-31

- **The liveness probe restarted pods that were merely busy.** Intermittent
  `Liveness probe failed: context deadline exceeded` and the same on readiness — on a
  handler that returns a literal and touches nothing. Both probe endpoints were sync
  `def`, so they ran in anyio's threadpool: 40 slots, shared with every other sync handler
  in this single-process app, and held for the duration of each `kubectl` subprocess or
  gateway call (`gateway.py` timeout=300, `modelhub` timeout=900). Past 40 concurrent
  blockers a handler that does nothing still waits behind the queue. Measured in a live
  pod: 39 blockers answered in 1.7ms, 45 never answered inside the probe's 5s, and the
  kubelet restarted a healthy pod. `/health` is `async def` now — on the event loop it
  cannot queue: 60 blockers, 0.8ms.
- Both copies are fixed. On a base-path install the kubelet reaches the OUTER
  `_root_health`, not the inner `health()` — patching only the inner one looks right in a
  diff and changes nothing in production.
- `readyz` stays sync **on purpose**: it runs `SELECT 1`, and an app with no free threads
  genuinely is not ready. Readiness pulling a busy pod out of the service is the correct
  response to saturation; liveness restarting it and killing in-flight work is not.
- Liveness is also slower to conclude — `timeoutSeconds` 5 → 10 and `failureThreshold` 6,
  so a minute of silence is required before a restart rather than fifteen seconds.
- `bin/probe-starvation-ab.sh` reproduces it inside a live pod, on spare ports, against
  throwaway databases with the agent loop off. It asserts its own preconditions because
  three separate mistakes produced confident, meaningless numbers while this was being
  diagnosed: patching the unreachable handler, a blocker that 404'd behind the StaticFiles
  mount, and a stale listener from an earlier run silently serving the old build.

## 1.6.31 · 2026-08-31

- **A lost datastore no longer means lost fix-classes.** The event chain is the durable
  record and `kb_fix` is an index over it, but nothing could rebuild one from the other — so
  a reinstall that took the volume with it left the Autonomy Board and Knowledge Base empty
  for good, while alerts and incidents regenerated and made the loss look partial.
  **Rebuild from the event chain** (Autonomy Board, admin only) recomputes the classes from
  the recorded outcomes: counters, the fix, and the status they imply. It previews before it
  writes. Validated against a live install's chain — 87 outcome events reproduced all 11
  existing classes exactly, creating none and updating eleven.
- **A rebuild deliberately does not restore consent.** `enabled_t0` and
  `local_model_verified` are never replayed: losing a database must not silently re-arm
  unattended action, so a class comes back at T1 with three of five gates green, waiting for
  a human to tick **enable T0** again. Both are now recorded on the chain (`t0_enable`,
  `t0_revoke`, `t0_verify`), so the original decision stays auditable — this refuses to act
  on it, it does not lose it. `set_t0` also records *who*.
- **Admin-only row deletes** on the Autonomy Board and the Approvals queue. Neither touches
  the chain: a deleted fix-class is recoverable with Rebuild, and a deleted approval keeps
  its proposal/approval/action/outcome events, so the incident trail still reads correctly.
  Deleting a fix-class also drops its per-signature breaker override.
- **History has no delete, by design.** The event chain is hash-linked, and a hole in it is
  indistinguishable from tampering — which is the property `/v1/events/verify` exists to
  check.

## 1.6.30 · 2026-08-31

- **Finetuning a Mistral base dropped every single row.** A run on Mistral-7B-Instruct-v0.3
  ended with `every training row's answer exceeded max_seq_length — nothing to train on`,
  8000 of 8000 train rows and 2000 of 2000 valid rows discarded — on a dataset whose rows
  are 88 tokens against a 1024 limit, so the advice to raise the limit could never have
  helped. The prompt-masking added with `mask_prompt` measured the prompt by rendering it
  SEPARATELY and assuming that render is a token prefix of the full one. Mistral's template
  breaks that assumption in both directions at once: it drops the system turn from the full
  render while merging it into the prompt render, so the "prompt" tokenised **longer than
  the entire sequence** (56 vs 41 on a real row), every label became -100, and each row
  looked over-length. The answer span is now located by character offset inside the one
  string that is actually tokenised, which needs no assumption about renders at all.
  Verified across all five bundled bases: Mistral goes 0/200 → 200/200 rows kept, and
  Llama, Qwen, gemma and granite label byte-identically to before.
- The drop message no longer misattributes the cause: it says how many dropped rows really
  do exceed `max_seq_length`, and says so when none of them do. A template that rewrites the
  assistant content now trains on the full sequence with a warning rather than discarding
  the row, and a base whose template drops the system turn says so once.

## 1.6.29 · 2026-08-31

- **The flap breaker can be set per fix-class, not just board-wide.** Each row on the
  Autonomy Board gains its own `inherit · demote · pause · off`, sitting beside
  `enable T0` with the other per-class controls. `inherit` is the default and follows the
  board, so nothing moves for an install that ignores this. The case it exists for: a demo
  induces a failure on purpose, the autonomous fix restarts it repeatedly, and the breaker
  demotes mid-demo — now that one class can be set `off` without unguarding every other
  autonomous class on the cluster. Overrides work in both directions: flip the board to
  `off` for a demo and a class pinned to `demote` stays protected.
  Keyed on the SIGNATURE rather than the kb_fix row, because the watchlist lane fires by
  signature and has no kb_fix row — a row-keyed override would silently have missed the
  one lane whose 300s cadence can actually trip the breaker (three fires take ~10min
  there, ~3h on the hourly lane). An override is sticky and shows as an amber badge on the
  row, so a demo left switched off is visible on the board rather than forgotten.
- **The Replay-verify hint follows the tooltips convention.** The button's five-sentence
  explanation moved from a native browser title to `data-tip`, so it appears only in
  💡 Tooltips mode — and now says plainly that a blind replay deriving the same verb is
  agreement with the ACTION, not evidence the action resolves the incident.

## 1.6.28 · 2026-08-31

- **Settings → Updates works again on a modern Docker.** The appliance's update engine
  was `containrrr/watchtower`, unmaintained since 2023 and still negotiating Docker API
  1.25 — every daemon >= 25 refuses it ("client version 1.25 is too old. Minimum
  supported API version is 1.40"), so it died on its first scan and the Update button
  could never do anything. Replaced with the maintained fork, pinned:
  `ghcr.io/nicholas-fedor/watchtower:1.21.0` (amd64 + arm64, same enable label, same
  env). The trigger is now a POST — the fork answers 405 to the GET the app used to
  send, while containrrr checked no method at all, so the call suits both. Note that
  1.6.27's "the next watchtower update pulls a ~26GB trainer image" could not actually
  have happened on a current daemon: nothing was updating.
- **A macOS resource fork no longer empties the Training Studio.** `._name.jsonl`
  siblings are not UTF-8; landing one in the dataset directory — via a Mac-authored
  air-gap bundle or `VKE_EXTRA_DATASETS` — raised `UnicodeDecodeError` inside the
  dataset listing and took the whole list down with it. Dotfiles are now skipped both
  where datasets are listed and where they are seeded onto the volume.
- **The Analytics tab's Act panel worked on the appliance and 500'd on DKubeX.** The
  reported half of dkubeio/vke#4 (`/v1/analytics`, `json_extract`) was fixed in 1.6.7, but
  the tab calls a second endpoint, and `/v1/analytics/act` still failed on every
  Postgres-backed install: `function datetime(unknown, unknown) does not exist`. The
  window was passed as a bound PARAMETER — `datetime('now', ?)` — and db.py's Postgres
  shim rewrites `datetime('now','-N days')` by regex, so a value hidden inside a parameter
  is invisible to it and the SQLite call reached Postgres raw. It is now the literal form
  the shim can see, which is why the same window in `reports.py` and `factory/data.py`
  never broke. Verified on a live Postgres install: 233 rows across all five event kinds
  where the shipped query raised.
- **Operators were told every namespace is read-only.** `GET /v1/rbac/write` — a
  read of what the cluster already allows — was gated at sre_lead, so it 403'd for
  operator, ml_engineer, exec and demo. Neither caller treats that as an error, so the
  failure was silent and wrong in two places: every Workloads card fell back to the
  "structurally read-only" chip regardless of the real grant, and the Action Console
  dropped its read-only warning entirely while still offering Execute to operators —
  the one role most likely to press it, now with no hint the API server would refuse.
  The status read is open to observers; flipping a grant stays admin/sre_lead on the
  POST. The workload chip stays truthful for everyone and is only clickable for the
  roles that can actually flip it.
- **Analytics told ml_engineer and demo there was nothing pending.** The page's "open
  improvement proposals" panel reads `/v1/approvals?status=pending`, gated at
  sre_lead/operator/exec — but Analytics is a deliberate view for ml_engineer and demo,
  so for them the call 403'd and the panel rendered its EMPTY branch, "no open proposals
  — nothing pending", however many were queued. Both that read and the proposal drawer
  behind each row are open to observers now; deciding an approval and marking one
  applied remain sre_lead/admin, and the drawer no longer offers a Mark-applied button
  to roles that cannot use it.
- **Operators can execute in the Action Console again — the button was never wired to a
  gate they could pass.** `POST /v1/actions/execute` was `APPROVERS`, while the console
  has always rendered "Execute now (logged)" for operator; pressing it 403'd, and the
  handler then matched "forbidden" against the app's own error and offered a
  fenced-write grant — diagnosing a role refusal as a namespace-RBAC one, and proposing
  a remedy that role could not apply either. The gate is now sre_lead + operator. The
  fence is untouched and is what keeps this safe: allowed kinds only, a replica cap, no
  delete route exists at all, every call on the event chain, and the cluster's own RBAC
  still decides per namespace. Approving and granting write remain sre_lead/admin.
- **"Run daily audit" no longer claims to have run.** `POST /v1/agentloop/run` is
  sre_lead/ml_engineer, but Reports offered the button to operator and exec, whose 403
  was swallowed — the toast said "Running daily audit…", the screen re-rendered, and
  nothing had happened. The button is now rendered only for roles that can use it, and
  a refusal is reported instead of being discarded.
- Found by sweeping every role × screen × endpoint the console can reach rather than by
  chasing reports — following helper calls, drawer kinds and onclick handlers, and
  separating a silent render-time 403 from a failed click: 4 render-time and 1
  actionable click-time blockage existed, 0 remain.
- **You choose what a flapping fix-class costs.** The T0 circuit breaker demoted on
  flap — status to `demoted`, and the `enabled_t0` opt-in cleared, which is an automatic
  process erasing the one graduation gate a human owns. The threshold also counts FIRES,
  not failures, so three *successful* remediations of one signature in 30 minutes demote a
  fix-class for doing its job. The Autonomy Board's policy card now carries **When it
  trips**: `demote` (the default — nothing changes for an install that ignores this),
  `pause` (skip the auto-fire and propose to a human for the rest of the window, leaving
  the tier and the opt-in alone) or `off`. Settings → Agent loop & autonomy mirrors it
  read-only, exactly as it already does for the T0 master switch.
- **A demotion is no longer silent.** `policy.py` wrote no events at all, so a fix-class
  dropping out of autonomy reached History, the event chain, Analytics and Telegram
  nowhere. Every demotion — breaker or regression — now appends `t0_demote` with its
  reason, and a demoted row on the board says what tripped it, when, and how to put it
  back.
- **The Autonomy Board's `successes` chip stops reading like a fraction.** It showed
  `4/3` one line under the row's `4/4 success` — but the row is successes/attempts while
  the chip is successes against the threshold of 3, so the same `x/y` shape meant two
  different things side by side. The chip now reads `4 · need 3`, and every gate chip
  carries a hover explaining what it actually measures — including that a failure stays
  in the success-rate denominator permanently, which is what raises the bar from three
  successes to nine.
- **The two auto-fire lanes agree on what a trip means.** The watchlist sweep and
  `can_autofire()` each counted the same in-memory fire log separately, and disagreed:
  one skipped a tick, the other demoted permanently. They now share
  `policy.breaker_tripped()`, and `off` disables the breaker on both.

## 1.6.27 · 2026-08-30

- **ONE trainer lineage: the unified image ships.** `vke-trainer:1.6.27` (and `latest`)
  is now the unified build — CUDA-torch that uses a GPU when present and falls back
  cleanly to CPU, with the full five-model air-gap bake. The "is this tag CUDA?"
  ambiguity is over: `cuda` and `cuda-1.6.27` alias the same image for one release of
  overlap, then the separate CUDA lineage retires.
- **A lean variant for clusters:** `vke-trainer:1.6.27-lean` (and `lean`) — the same
  unified build without the baked models (~3GB vs ~26GB), for Kubernetes installs that
  seed `/models` from a volume (the DGX pattern) and for small-disk hosts.
- **Heads-up for auto-updating appliances:** `latest` moving onto the unified fat
  lineage means the next watchtower update pulls a ~26GB trainer image. Pin the
  trainer tag first if that is unwelcome on your link or disk.
- Build fold-in: `bin/build-trainer-unified.sh` makes the two-variant, two-arch build
  reproducible (native arm64 with stream-to-registry; the amd64 half on any rented
  x86 box via `AMD64_BUILDER`).

## 1.6.26 · 2026-08-30

- **Rollouts no longer hang on base-path installs.** The readiness probe hits the
  container port at the root, but under a base path the app only answered
  `/<base>/readyz` — so a chart pointing readiness at `/readyz` left the pod
  not-Ready forever. `/readyz` now answers at the root too, exactly as `/health`
  always has.
- **Postgres installs no longer grow an empty snapshots directory.** Listing backups
  on a Postgres-backed install returns cleanly without creating litter beside a
  database file that does not exist.

## 1.6.25 · 2026-08-30

- **Ask the Database now works on Postgres installs.** The tile hard-opened the SQLite
  path and returned a 500 on every Postgres-backed deployment. It now follows the
  backend the app actually runs: SQLite keeps the engine-level authorizer; Postgres
  introspects the schema over the app's own connection behind a four-layer in-process
  fence (comment-stripped statement validation, a fail-closed table allowlist, a
  genuinely read-only transaction, a statement timeout) — honestly documented as
  weaker than an authorizer, with a clamped row limit that caps the model's LIMIT but
  never raises it.
- **A pod with an unreachable database no longer reports Ready.** New `/readyz` probe
  touches the datastore; liveness stays database-free on purpose, so a store outage
  pulls the pod from the service instead of restarting it in a loop.
- **The data volume survives uninstall/reinstall.** The chart's claim is annotated
  `helm.sh/resource-policy: keep` — the event chain, knowledge base, approvals and
  identity are a system of record, not scratch. Reclaiming the disk now takes an
  explicit `kubectl delete pvc`. New installs get 8Gi; existing claims keep their size.
- **Real snapshots of the datastore.** `VACUUM INTO` copies of the live database with
  manifests recording checksums and every stream's chain head — so a restore can prove
  it restored everything, not merely something valid. Admin endpoints + a daily job;
  restore stays a documented operator procedure, never an API.
- Also: the `default` workspace now seeds on Postgres, and the event stream-head lookup
  gained the index its every-append hot path deserved.

## 1.6.24 · 2026-08-30

- **The audit chain can no longer fork — and a fork is no longer called tampering.**
  Concurrent writers (the scheduler racing an HTTP request, sync racing the async
  batch writer) could fork the hash chain, and one benign fork made the whole ledger
  read as BROKEN. All event writes are now serialized behind one lock with write-time
  timestamps, and the verifier separates **altered** (a row failing its own hash — the
  real tamper signal, no longer cascading) from **forks** (a historical concurrency
  artifact; nothing edited). The Trust Center shows three states: green intact, amber
  unaltered-with-historical-forks, coral only for genuine alteration. Proven with a
  7-thread stress: 840 concurrent events, zero forks, zero drops.
- **The trainer finally trains on the answer, not the question.** `mask_prompt` — in
  every job spec since the MLX trainer — was a no-op on the shipping CUDA/CPU trainer:
  ~70% of every sequence was gradient on the persona and the user's question. Labels
  now cover only the assistant turn. The trainer also keeps the **best** iterate by
  validation loss (with early stopping) instead of always shipping the last, evaluates
  on the whole valid split, and datasets **split before padding** so tiny corpora no
  longer leak training rows into validation.
- **Trainer images `1.6.24` and `cuda-1.6.24` ship these as overlays** on the existing
  five-model bakes — same baked weights, no re-download for layer-deduped pulls.

## 1.6.23 · 2026-08-30

- **One image fault, one signature.** `ErrImagePull` now folds into `ImagePullBackOff`
  at the reason-canonicalization layer — a broken image oscillates between the two
  kubelet phases, and a fix graduated on one phase could never auto-fire while the pod
  sat in the other (the second independent cause of "intermittent autofix"). The raw
  kubelet reason still shows in the alert detail.
- **The trainer's memory gate reads the honest number on unified-memory GPUs.** On
  Grace-Blackwell/GB10-class parts, CUDA's "free" collapses after any big file read
  because page cache counts against it — refusing runs that would fit fine. The
  preflight now sizes against the kernel's MemAvailable (capped by device total) on
  unified parts only; discrete cards and the refuse-not-OOM stance are unchanged — a
  genuinely busy box still refuses cleanly.
- **Trainer images updated by overlay.** `vke-trainer:1.6.23` and `cuda-1.6.23` carry
  the new gate as a single small layer on the existing five-model bakes — no re-bake,
  same baked weights.

## 1.6.22 · 2026-08-29

- **The fast watchdog can no longer be frozen by a stale proposal.** A single pending
  HITL approval for a signature used to block that watch rule's ENTIRE auto path on
  every fast sweep — auto-fixes appeared only ~hourly. The pending-dedup now gates
  only the propose branch; an armed auto rule fires regardless (all safety gates —
  fence, master switch, circuit breaker — unchanged) and an autonomous apply
  supersedes any stale pending proposal so it can never re-freeze autonomy or be
  double-applied later.
- **History and the incident trail stay live between hourly sweeps.** The fast (300s)
  watchdog cycle now records the observation snapshot and one incident per firing
  alert — deduped per signature within the window — so a new failure surfaces within
  one fast tick instead of up to an hour, with no event-log spam.
- **A unified CUDA trainer image joins the build set.** One CUDA-torch trainer that
  uses a GPU when present and falls back cleanly to CPU, with the full five-model
  air-gap bake, a resilient retrying downloader, and a byte-completeness validator
  for the baked weights. Additive: the existing CPU and CUDA Dockerfiles are
  untouched this release.

## 1.6.21 · 2026-08-29

- **Graduation no longer needs a manual scavenger hunt.** From a live "why won't my
  fix auto-remediate" session, four fixes: the Autonomy Board gains a **Replay-verify
  button** right next to the failing local-verified gate; the **Benchmarks tile now
  shows for the SRE lead** (it was hidden from the very role driving graduation); the
  graduation sweep **auto-runs the replay check** for any class that clears the
  success/rate/fence gates (the gate itself is unchanged — the local model must still
  reproduce the approved verb blind); and a fully-green, T0-enabled class can no
  longer freeze at "proving" — the sweep re-runs promotion, so an earned graduation
  always lands at autonomous.
- **Watchlist rules are target-aware.** A rule whose fix names a specific workload now
  fires only when a firing alert of that reason actually references that workload —
  one workload's rule can no longer remediate every unrelated pod that trips the same
  generic reason. Reason-only rules behave exactly as before.

## 1.6.20 · 2026-08-28

- **Postgres installs fixed: approve no longer 500s, the incident chart no longer
  reads empty.** Two SQLite-isms bit DKubeX/Postgres installs — the approval
  outcome column was never created on Postgres (approve → HTTP 500 with a stuck
  row, after the fix had already run), and the incident-trail window used
  SQLite-only date arithmetic (trail → 500 → all-zero sections). Both queries are
  now portable; existing Postgres installs pick the column up on next start.
- **The trainer refuses metadata-only model stubs.** A base now counts as on-disk
  only when its weight shards actually exist — an interrupted download can no
  longer skip the air-gap guard and then fail at load; connected installs resume
  the pull, sealed installs get a precise error. (Ships in the CUDA trainer images
  now; the fat CPU-trainer rebuild with Mistral baked in follows as a
  trainer-only push.)
- **The Studio picker now verifies the catalog against the trainer's disk.** A new
  trainer `GET /bases` endpoint reports which base models are physically present in
  /models, and the picker reconciles every entry against it — a base the trainer
  actually has can never again be mislabeled "downloads from HF" by a stale chart or
  compose environment (the env-lies-about-the-image class, closed at the source).
  Old trainers without the endpoint fall back to today's behavior.

## 1.6.19 · 2026-08-28

- **Approvals decide is deterministic — one source of truth.** Deciding a proposal now
  re-renders the queue from a single fresh fetch, so the decided row reliably leaves
  Pending and appears under Recent remediation chains with the correct status. The toast
  reads the authoritative recorded status (applied / denied / failed) instead of the live
  response — and if the response is lost behind a slow gateway, the app reconciles
  against the server's recorded status rather than reporting a false failure. Double-
  clicks are guarded. (Community fix, merged from PR #8.)
- **Settings that teach.** Every Settings field now carries a compact hint with a
  concrete example, every toggle states what ON vs OFF results in, each section opens
  with a one-line "what this controls", and the genuinely risky controls (chat gateway
  URL + auth, the T0 master switch) are flagged ⚠ high-impact with the consequence
  spelled out. Integration fields (air-gap channel, RunPod, EKS…) gain per-field hints.
  (From PR #9.)
- **Tooltips mode — hover to learn.** A new toggle (sidebar footer + topbar 💡, all
  roles) turns on themed hover popovers across the console: sidebar navigation, the
  chrome toggles, the Approvals Apply/Deny buttons, the incident six-step stepper and
  key Settings fields. Viewport-aware, honors reduced-motion, Esc/scroll dismissal —
  and OFF leaves the app exactly as before. (From PR #9.)
- **The guide arc gets its own phasedoc window** (an internal builders' cockpit; not
  part of the shipped product surface).

## 1.6.18 · 2026-08-28

- **Chart upgrades no longer crash on `--reuse-values`.** Helm's `--reuse-values` keeps the
  previous release's values and does not merge new chart defaults, so upgrading an older
  install to a chart that later gained an optional block (vllm · air-gap · trainer ·
  persistence) crashed with a nil-pointer at the first template line. Every optional-block
  toggle is now nil-guarded — the block simply stays off when its values are absent, and the
  default render is byte-identical. (Community fix, merged from PR #7.)
- **Version sync.** The application and chart move together again at 1.6.18; there are no
  application code changes since 1.6.17.

## 1.6.17 · 2026-08-28

- **Answers now read like a documentation manual.** Every streamed chat answer renders
  real formatting — headers, paragraphs, lists, code blocks, bolded Diagnosis/Likely
  cause/Next step/Fence labels, citation pills — via a small built-in renderer (no
  external libraries, air-gap-safe). The three-section trained-model answer became
  properly spaced stacked boxes with the training-data rows as clean cards, and
  citations became a References block: numbered source cites click through to the
  highlighted span in the document, known-fix cites list signature, verification and
  the fix text.
- **Dataset variants: one upload, many training views.** A record store can now project
  multiple named training views — pick a different target column, a format
  (classification · Q&A · instruction), optionally a row filter — each variant is a
  first-class dataset in every picker and trainable in the Studio; the base view is
  never touched and every variant creation lands on the event log.
- **The Action Plan replaces browser dialogs.** Propose-as-fix from chat, every alert's
  new ⚡ Plan button and the apply flows now open one structured Action Plan box:
  cluster, fenced action type, target workload from a live dropdown, replicas, a fence
  preview that shows the namespace's read/write state, then Propose → Approvals or
  Execute now. No browser prompt/confirm dialogs remain in the fix flows.
- **The remediation chain on one screen.** Approvals persist their apply outcome; a
  Recent remediation chains card reads proposed → approved → applied/failed with the
  outcome note on one line each, and deciding updates the row inline without a reload.
  Proposals also link their event, so the drawer converts an approved proposal into a
  reusable playbook in one click.
- **Act outcomes analytics.** The Analytics page gains an Act panel straight off the
  event chain: proposals/approved/denied/actions/applied/failed, success rate by
  signature, the auto-vs-HITL split, and the recent action→outcome trail — the same
  rows History shows.
- **Ask the Database, more intuitive.** Suggested questions are derived from each
  source's real schema and value vocabulary, tables and columns render as clickable
  chips (low-cardinality columns show their values), and results render as proper
  striped tables with right-aligned numbers — the visible-SQL receipt stays.
- **Two navigation bugs fixed.** Every cross-screen navigation was silently rendering
  twice (killing the alert → Diagnose chat handoff), and the incident trail returned
  404 for any signature containing a slash. Both fixed; Diagnose now lands its turns
  on the incident trail reliably.

## 1.6.16 · 2026-08-28

- **One-click per-namespace write access — frictionless, and safe by construction.**
  Until now, an in-cluster install hitting "cannot patch … is forbidden" needed a helm
  upgrade to grant write. Now: enable `rbac.selfServiceWrite=true` ONCE in the chart and
  every workload card (and the Settings page) gains a read/write toggle per namespace.
  The mechanism is the Kubernetes `bind`-verb pattern: the chart creates ONE fenced
  write ClusterRole (scale · rollout-restart — never delete) and grants the app only
  the right to bind THAT role, so the API server itself refuses any broader grant even
  if the app were compromised (proven live: a cluster-admin bind attempt is rejected
  by Kubernetes, not by us). Toggles are admin/sre_lead-only and every grant/revoke
  lands on the tamper-evident event log. All namespaces still start read-only.
- **The action console explains "forbidden" honestly.** An RBAC denial now shows
  "namespace is read-only" with a one-click *enable fenced write + retry* — instead of
  looking like a fence block.
- **Settings → Cluster write access** shows the live picture (self-service active /
  cluster-wide static / structurally read-only) with per-namespace toggles or the exact
  one-time enablement command.

## 1.6.15 · 2026-08-28

- **The Agent Loop is now a watchdog console.** Four tabs — Overview, Watchlist, Jobs,
  History — with a grouped view of every sweep the loop runs.
- **The watchlist: pre-authorized remediation per failure signature.** Author a rule
  binding a fenced fix to a signature; when that signature fires, the fix is proposed
  to the approval lane — or, ONLY if the rule is explicitly set to auto AND armed AND
  the global watchdog master switch is on (default off), applied automatically through
  the same fence, circuit breaker, audit chain and Telegram notification the T0 lane
  uses. New rules always start in propose mode, unarmed.
- **Custom scheduled jobs.** Add your own jobs to the agent loop's schedule from the
  console; job runs are grouped and inspectable.
- Playbook-first watchdog remediation and authored-artifact surfacing round out the
  enhancement-2 set.

## 1.6.14 · 2026-08-28

- **Structured remediation proposals.** A proposal now carries Why / How / Verify /
  Reversal — reviewed in its own drawer on Approvals — and an applied fix can be
  marked as such, closing the loop on the record.
- **Convert any event into an artifact.** From an event's receipt drawer, one click
  turns it into a playbook, a runbook, a watchdog alert rule, or a chat preset card —
  with a coverage panel showing what already covers that signature (or that it's
  net-new) before you author a duplicate.
- **A watchdog alert-rule editor on the Alerts page.** Author threshold rules
  (restarts / phase / ready / reason, per pod or node) right in the console; the
  hourly sweep honors them.
- **Authored chat preset cards.** User-authored cards overlay the built-in decks per
  model. All air-gap-first: every new surface works sealed.

## 1.6.13 · 2026-08-27

- **The Training Studio picker can no longer contradict the chat model.** Three
  distribution surfaces had drifted after the granite swap — the cloud twin's fallback
  catalog and BOTH Helm charts still listed the SmolLM2-era lineup while chat served
  granite. The fresh-box catalog is aligned to the shipped bundle, the published chart
  is corrected (install with `--version 1.6.12+`), and the app now **self-heals stale
  environments**: installs whose `VKE_BASES` predates the swap still show granite
  (container-trainer shapes) and Mistral (every unsealed shape) in the picker.
- **The studio manual ships on the documentation page.** How a CSV becomes both a
  trained model and its retrieval source, which base to pick, and the batch/iteration
  coverage math with verified timings — with an architecture diagram.

## 1.6.12 · 2026-08-27

- **Export a trained model from the Studio — adapter + model card, never the base.**
  A small Export button sits beside Promote / Test / Set default on every trained
  model's row. It downloads a zip holding the LoRA adapter only (~10–20MB — the base
  model stays IBM's/Meta's to download) plus a model card (JSON + markdown) with the
  full provenance: base model, dataset name, schema, row count, format, training
  parameters, final/validation loss, serving version, and the VKE version that
  trained it. Works on split-trainer installs too — the trainer now serves its
  adapters over its own API.
- **Mistral 7B shows in every Training Studio picker.** Existing installs keep their
  original compose environment forever (image updates don't touch compose), and the
  native shape only listed models already on disk — so Mistral was invisible almost
  everywhere. The catalog knowledge now lives in the app: unsealed installs always
  offer Mistral as "downloads on first train"; sealed installs still hide it
  (an air-gapped picker must never advertise a base it cannot fetch — the signed
  bundle carries the weights instead).
- **Chat answers carry a confidence verdict and a source-conflict flag.** Every answer now
  shows a deterministic confidence chip (high = a verified known fix matched · medium =
  grounded in retrieved sources · low = ungrounded), and when two known-fix records
  prescribe *different fenced verbs* for the same failure signature, the answer is flagged
  "⚠ sources differ" with both sources named — instead of silently letting one win. The
  verdict is computed from the grounding, never by the model, so it cannot flatter itself.
- **Known-fix retrieval ranks by the named workload.** A question naming a specific
  deployment now retrieves THAT workload's fix records ahead of the generic playbook and
  ahead of records for adjacent workloads (the name token is the strongest join key).
- **Adapter-import fix (granite-fatal on fresh volumes).** On a fresh forge volume whose
  base was already imported by a previous trainer pod, the adapter-only import path died on
  a missing directory and silently fell back to the merged-GGUF path — which granite's
  tokenizer cannot survive. One mkdir; the adapter path now holds everywhere.
- **A 1.6GB lean trainer for small hosts.** `--build-arg BAKE_BASES=0` builds the trainer
  without the ~19GB of baked base weights; `deploy/airgap/compose.trainer-lean.yml` mounts
  the signed bundle's models/ directory instead (same weights, on disk once). Verified with
  a real granite train from mounted bases; published as `vke-trainer:lean`. The stock
  appliance image is unchanged.
- **The GPU trainer image is validated on both architectures.** `vke-trainer:cuda` is a
  multi-arch tag whose arm64 half trained granite on an NVIDIA GB10 (98s) and whose amd64
  half trained granite on an RTX A6000 (69s) — both through the sidecar + adapter pipeline.

## 1.6.11 · 2026-08-27

**Granite 4.2 3B replaces SmolLM2 + qwen-1.5 as the bundled brain.** One Apache-2.0 dense
3B (ChatML, 512K context, reasoning-capable) is now both the trainable base (bf16 in the
trainer, with IBM's official Q4_K_M GGUF as a sidecar) and the chat model (baked into the
ollama image). Granite's tokenizer is unknown to the pinned GGUF converter, so its base
imports from the official GGUF and finetunes ride as adapters — no converter change.
Granite THINKS by default and silently spends the whole budget in the thinking channel;
chat sends `think: false` for granite backings. SmolLM2 stays available on-demand.

**Trained models stop looping.** An overtrained small model loses its end-of-turn habit
on novel prompts and self-QA-loops to the token budget (reproduced with SmolLM2 at 10
epochs); every trained import's Modelfile now carries `repeat_penalty 1.3` and an output
cap.

**Mistral-7B ships in the air-gap bundle.** It was "on-demand from HuggingFace" — the one
thing a sealed install cannot do; the bundle now carries the weights and mounts them into
the trainer (`BUNDLE_MISTRAL=0` to skip).

**Trained-model answers come in three sections.** Pick a trained alias in chat and every
answer is structured: **① From the training data** — deterministic retrieval from the exact
dataset the model was trained on, cited by dataset + row numbers (the facts live in the
data, not the weights); **② Live cluster & learned context** — the live cluster picture and
matching known fixes/history, shown only when the live-cluster toggle is on (off =
dataset-only mode: the model is instructed to use nothing beyond the ① rows and to say so
when they don't cover the question); **③ the reasoned answer**, streamed below, following
the Diagnosis/Likely cause/Next step/Fence contract with its source citations.

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
