# ADR 0001: Local cluster and registry

## Status

Accepted

## Context

The reference environment must run entirely on a developer machine except for remote Git. Images must use immutable tags and be deployable via Git changes that ArgoCD reconciles (never by re-pushing `:latest`). Candidates: kind, k3d, Minikube; image delivery via local registry or cluster image-load.

## Decision

Use **k3d** with its **built-in local registry**.

### Why k3d

- Fast create/destroy for scripted `./scripts/cluster-up.sh` / `./scripts/cluster-down.sh`
- First-class local registry: `docker build` → `docker push <local-registry>/service-x:<immutable-tag>` → bump tag in Git → ArgoCD → cluster **pulls** the new tag
- Closest local analogue to production GitOps image promotion without Docker Hub
- Named explicitly in the assignment as an acceptable registry approach

### Alternatives considered

| Option | Why not chosen for this reference |
|--------|-----------------------------------|
| **Minikube** | Familiar and valid; heavier; `image load` or registry addon is more awkward than k3d’s built-in registry |
| **kind** | Valid; typical path is `kind load`, which is less like “pull after Git tag bump” unless an extra registry is wired |
| **Docker Hub / GHCR** | Remote runtime dependency; needs extra credentials; conflicts with “only Git is remote” |

### Image tagging

- Tags are immutable (`<git-sha>` or semver), never `:latest` for deploy
- A new version is a **Git change** to the image tag in the Kustomize overlay, not a retag/push of the same mutable tag

## Consequences

- Prerequisites include Docker, kubectl, and k3d
- Manifests reference the local registry hostname used by the bootstrap scripts
- Engineers without k3d experience need a short README section; Kind/Minikube remain possible forks of this design
