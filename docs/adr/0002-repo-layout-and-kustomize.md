# ADR 0002: Repo layout and manifest tooling

## Status

Accepted

## Context

We have two Quarkus application repositories (`service-a`, `service-b`). Deployment state must live in Git for ArgoCD. We need clear separation between app code and cluster config, plus env-specific differences (AC: overlays).

## Decision

### Three repositories

| Repo | Responsibility |
|------|----------------|
| `service-a` | Caller Quarkus source, tests, Dockerfiles |
| `service-b` | Callee Quarkus source, tests, Dockerfiles |
| `gitops` (this repo) | Kustomize manifests, ArgoCD Applications, bootstrap/teardown, image tag bumps |

App changes and deploy changes have separate histories. ArgoCD watches this repo for desired cluster state.

### Manifest tooling: Kustomize

- `apps/<service>/base` — Deployment, Service, probes shared by environments
- `apps/<service>/overlays/local` — local/k3d image registry, replicas, and other env deltas
- At least one overlay (`local`) satisfies the “separated per environment” acceptance criterion

Helm was rejected as unnecessary complexity for two simple services.

### ArgoCD Applications in Git

Application CRs live under `argocd/applications/` so the GitOps control plane is itself declarative (app-of-apps / root apply at bootstrap).

## Consequences

- Image build stays in app repos (or scripts that know their paths); **tag bump commits land here**
- The gitops GitHub repo is public; ArgoCD needs no repository credentials
- Adding a third service means a new `apps/<name>` tree plus an Application CR
