# VKE — the Virtual Kubernetes Engineer · self-contained appliance

A self-improving SRE platform in a box: it observes a cluster, proposes fenced fixes with
human approval, and **trains its own local models on incident history** — and this bundle
carries *everything*: the app, the AI models, a real trainer, and the sample datasets.

**Product page / betadoc → https://t4tarzan.github.io/vke-appliance/**

## Quickstart

```bash
curl -O https://raw.githubusercontent.com/t4tarzan/vke-appliance/main/docker-compose.yml
docker compose up -d
open http://localhost:9040
```

That's it. After the image pull, nothing leaves your machine — no accounts, no API keys,
air-gap friendly. Runs on Apple-silicon Macs and NVIDIA DGX/Grace boxes alike (linux/arm64).

| Sign in as | User | PIN |
| --- | --- | --- |
| ML engineer (the Training Studio) | `U-ML` | `3333` |
| SRE lead (approvals, incidents) | `U-LEAD` | `1111` |
| Operator (observe, chat) | `U-OPS` | `2222` |
| Exec (analytics, flywheel) | `U-EXE` | `4444` |
| Admin (everything) | `U-ADM` | `9999` |
| Read-only demo | `U-DEMO` | `0000` |

## What's in the bundle

| Image | What it carries |
| --- | --- |
| `ghcr.io/t4tarzan/vke` | The console — ~35 role-gated tiles across Observe · Converse · Act · Learn · Oversight · Admin, with a bundled synthetic cluster snapshot |
| `ghcr.io/t4tarzan/vke-ollama` | Ollama with **qwen2.5:1.5b** (chat / the `k8s-sre` alias) and **qwen2.5:0.5b** baked in |
| `ghcr.io/t4tarzan/vke-trainer` | A real LoRA trainer: HF peft on CPU (works on a laptop), with the **Qwen2.5-0.5B base weights bundled** |

Bundled datasets (already in the Training Studio when you open it):

- **sre-pods-100** — 100 SRE incident→fix rows (CrashLoopBackOff, OOMKilled, ImagePullBackOff, …)
- **sre-pods-append-50** — 50 more rows, for the "append data → train v2 → watch the loss drop" story
- **k8s-troubleshooting** — a small starter Q&A set

## The 10-minute tour

1. Sign in as `U-ML / 3333` → open **Training Studio**.
2. **① Model**: the bundled Qwen2.5-0.5B base. **② Data**: pick `sre-pods-100` — or upload your
   own JSONL/CSV (append mode grows a dataset).
3. **③ Train**: "Estimate & train" shows the cost ($0 — it's your CPU) and wall-clock, then
   **Confirm & start**. A genuine LoRA run streams its loss curve live (~2–5 min on a laptop).
4. **④ Watch**: the run lands in the history; train again on `+ append-50` and the **v1 → v2
   overlay** shows the improvement.
5. **⑤ Serve & Chat**: the trained model is merged → GGUF → imported into the bundled Ollama
   automatically. **Promote** hot-swaps the `k8s-sre` alias onto it; **Test** it in place;
   **Open in Chat** and talk to the model you just trained.

Also worth a look: the fenced Action Console + approval queue, the hash-chained event log
(Trust Center → verify the chain), and the Iterative Demo tile, which switches from a staged
story to your real loss curves once two runs exist.

## Operational notes

- `VKE_PORT=8080 docker compose up -d` to change the port.
- Trained models persist in the `ollama-data` volume; app state in `vke-data`; training
  scratch in `forge`. `docker compose down -v` resets everything to factory.
- The cluster is a bundled synthetic snapshot (`VKE_CLUSTER_MODE=demo`). Pointing VKE at a
  real cluster (kubeconfig / in-cluster Helm deploy) is part of the full product.
- Images are linux/arm64 (Apple silicon, DGX/Grace). amd64 builds on request.
