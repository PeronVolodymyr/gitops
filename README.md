# gitops

Declarative deployment for the Quarkus HTTP demo (`service-a` caller → `service-b` callee).

Sibling layout (expected):

```text
IdeaProjects/
  service-a/   # Quarkus caller
  service-b/   # Quarkus callee
  gitops/      # this repo — manifests, ArgoCD, bootstrap
```

## Design decisions

See:

- [docs/adr/0001-local-cluster-and-registry.md](docs/adr/0001-local-cluster-and-registry.md) — **k3d + local registry**
- [docs/adr/0002-repo-layout-and-kustomize.md](docs/adr/0002-repo-layout-and-kustomize.md) — app repos vs gitops, Kustomize overlays

## Prerequisites

- Docker
- kubectl
- [k3d](https://k3d.io/)
- JDK 21 (to build the Quarkus apps)
- `make`
- Remote GitHub repo https://github.com/PeronVolodymyr/gitops — ArgoCD reconciles from Git, not from a local path
- If the repo is private: register credentials with ArgoCD (see bootstrap step 2) — **never commit credentials**

## Repository layout

```text
apps/
  service-a|b/
    base/                 # Deployment, Service, probes
    overlays/local/       # image registry + immutable tag
argocd/applications/      # ArgoCD Application CRs (in Git)
scripts/                  # bootstrap, build/push, tag bump
Makefile
```

Service A reaches B via Kubernetes DNS: `http://service-b:8080`  
(`QUARKUS_REST_CLIENT_SERVICE_B_URL` in the Service A Deployment).

Probes: `/q/health/live`, `/q/health/ready`.

## Bootstrap (clean machine)

> Argo CD install must use **server-side apply** (`kubectl apply --server-side --force-conflicts ...`). Plain `kubectl apply` can fail on the ApplicationSet CRD (annotation size limit).

Argo CD Application CRs in Git hardcode this repo:

`https://github.com/PeronVolodymyr/gitops.git`

1. Ensure this repository is pushed to that remote (already done if you use that GitHub URL).

2. If the repo is **private**, create an ArgoCD repository secret (skip for public):

```bash
kubectl -n argocd create secret generic gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/PeronVolodymyr/gitops.git \
  --from-literal=username=YOUR_GITHUB_USER \
  --from-literal=password=YOUR_TOKEN
kubectl -n argocd label secret gitops-repo argocd.argoproj.io/secret-type=repository
```

3. Build and push initial immutable images, bump tags in Git, push:

```bash
TAG=0.1.0 make release-b
TAG=0.1.0 make release-a
git add apps/*/overlays/local/kustomization.yaml
git commit -m "Set initial image tags 0.1.0"
git push
```

4. Create cluster, install ArgoCD, register Applications:

```bash
make up
```

Manual Applications (no scripts):

```bash
kubectl apply -f argocd/applications/service-a.yaml
kubectl apply -f argocd/applications/service-b.yaml
```

5. Wait until both Applications are Synced/Healthy:

```bash
make sync-status
# or: make wait
```

6. Verify (port-forward):

```bash
kubectl -n demo port-forward svc/service-a 8080:8080
curl -s http://localhost:8080/api/v1/aggregate
```

### Teardown

```bash
make down
```

## Image build and immutable tags

Never deploy `:latest`. Promote by:

1. `TAG=<new> make release-b` (or `release-a`) — builds, pushes to `k3d-quarkus-registry.localhost:5001/...`, updates overlay `newTag`
2. Commit + push the overlay change
3. ArgoCD syncs the new tag (no mutable retag)

```bash
TAG=$(git -C ../service-b rev-parse --short HEAD) make release-b
git add apps/service-b/overlays/local/kustomization.yaml && git commit -m "Bump service-b image" && git push
```

## Demonstrations (Definition of Done)

### Resilience (Service B unavailable)

```bash
kubectl -n demo scale deploy/service-b --replicas=0
curl -i http://localhost:8080/api/v1/aggregate   # via port-forward to service-a
# Expect documented failure/fallback from Service A (e.g. 503)
kubectl -n demo scale deploy/service-b --replicas=1
```

### Live upgrade via Git

```bash
TAG=0.1.1 make release-b
git add apps/service-b/overlays/local/kustomization.yaml
git commit -m "Release service-b 0.1.1" && git push
# Watch ArgoCD roll the Deployment to the new immutable tag
kubectl -n argocd get applications -w
```

## Manual Kustomize check (optional, not the normal path)

Normal path is Git → ArgoCD. For learning only:

```bash
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k apps/service-b/overlays/local
kubectl apply -k apps/service-a/overlays/local
```

## Out of scope

Hosted CI/CD, Ingress, service-to-service auth.
