# ADR 0002: Repo layout and manifest tooling

## Status

Accepted

## Context

We have two Quarkus application repositories (`service-a`, `service-b`). Deployment state must live in Git for ArgoCD. We need clear separation between app code and cluster config, plus env-specific differences (AC: overlays).

## Decision

### Three repositories

| Repo | Responsibility |
|------|----------------|
| `service-a` | Caller Quarkus source, tests, Dockerfile, **Maven package + image build/push** |
| `service-b` | Callee Quarkus source, tests, Dockerfile, **Maven package + image build/push** |
| `gitops` (this repo) | Kustomize manifests, ArgoCD Applications, bootstrap/teardown, **immutable tag bump** |

App changes and deploy changes have separate histories. ArgoCD watches this repo for desired cluster state.

### Build vs promote

- **Build** (`./mvnw package`, `docker build` / `docker push`) lives only in each app repo (`scripts/build-and-push.sh`). This repo never invokes builds.
- **Promote** (update Kustomize `newTag`, commit, ArgoCD sync) lives in this repo (`make bump-*`).

### Manifest tooling: Kustomize

- `apps/<service>/base` — Deployment, Service, probes shared by environments
- `apps/<service>/overlays/local` — local/k3d image registry, replicas, and other env deltas
- At least one overlay (`local`) satisfies the “separated per environment” acceptance criterion

Helm was rejected as unnecessary complexity for two simple services.

### ArgoCD Applications in Git

Application CRs live under `argocd/applications/` so the GitOps control plane is itself declarative (app-of-apps / root apply at bootstrap).

## Consequences

- Each service can be built and pushed from its own clone without a sibling `gitops` checkout
- Tag bump commits land here; image artifacts are produced by the app repos
- The gitops GitHub repo is public; ArgoCD needs no repository credentials
- Adding a third service means a new app repo with `scripts/build-and-push.sh`, plus `apps/<name>` and an Application CR here
