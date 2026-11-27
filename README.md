# gitops

Declarative deployment for the Quarkus HTTP demo (`service-a` caller → `service-b` callee).

Sibling layout (expected):

```text
IdeaProjects/
  service-a/   # Quarkus caller — source, tests, scripts/build-and-push.sh
  service-b/   # Quarkus callee — source, tests, scripts/build-and-push.sh
  gitops/      # this repo — manifests, ArgoCD, bootstrap, tag bump
```

Image **build/push** lives in each app repo. This repo only **bumps** the immutable tag in Kustomize and reconciles via ArgoCD.

## Design decisions

See:

- [docs/adr/0001-local-cluster-and-registry.md](docs/adr/0001-local-cluster-and-registry.md) — **k3d + local registry**
- [docs/adr/0002-repo-layout-and-kustomize.md](docs/adr/0002-repo-layout-and-kustomize.md) — app repos vs gitops, Kustomize overlays

## Prerequisites

- Docker
- kubectl
- [k3d](https://k3d.io/)
- JDK 21 (to build the Quarkus apps)
- Public remote GitHub repo https://github.com/PeronVolodymyr/gitops — ArgoCD reconciles from Git, not from a local path

## Repository layout

```text
apps/
  service-a|b/
    base/                 # Deployment, Service, probes
    overlays/local/       # image registry + immutable tag
argocd/applications/      # ArgoCD Application CRs (in Git)
scripts/                  # bootstrap, tag bump
```

Service A reaches B via Kubernetes DNS: `http://service-b:8080`  
(`QUARKUS_REST_CLIENT_SERVICE_B_URL` in the Service A Deployment).

Probes: `/q/health/live`, `/q/health/ready`.

## Bootstrap (clean machine)

> Argo CD install must use **server-side apply** (`kubectl apply --server-side --force-conflicts ...`). Plain `kubectl apply` can fail on the ApplicationSet CRD (annotation size limit). The install script already does this.

Argo CD Application CRs in Git hardcode this repo:

`https://github.com/PeronVolodymyr/gitops.git`

1. Ensure this repository is pushed to that remote (already done if you use that GitHub URL).

2. Create the local cluster **and registry** (required before any image push):

```bash
./scripts/cluster-up.sh
```

(`cluster-up.sh` is safe if the cluster already exists — it skips recreate.)

3. Build and push initial immutable images from the app repos, then bump tags here and push:

```bash
(cd ../service-b && ./scripts/build-and-push.sh 0.1.0)
(cd ../service-a && ./scripts/build-and-push.sh 0.1.0)
./scripts/bump-image-tag.sh service-b 0.1.0
./scripts/bump-image-tag.sh service-a 0.1.0
git add apps/*/overlays/local/kustomization.yaml
git commit -m "Set initial image tags 0.1.0"
git push
```

4. Install ArgoCD and register Applications:

```bash
./scripts/install-argocd.sh
./scripts/configure-argocd-repo.sh
```

5. Open the Argo CD UI and confirm both apps are **Synced** / **Healthy**:

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

Open https://localhost:8081 (accept the self-signed certificate). Username: `admin`. Password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

CLI check: `kubectl -n argocd get applications`

6. Verify the apps (port-forward Service A):

```bash
kubectl -n demo port-forward svc/service-a 8080:8080
curl -s http://localhost:8080/api/v1/aggregate
```

### Teardown

```bash
./scripts/cluster-down.sh
```

## Image build and immutable tags

Never deploy `:latest`. Promote by:

1. Build and push from the **app** repo
2. Bump the overlay `newTag` in **this** repo
3. Commit + push so ArgoCD syncs (no mutable retag)

```bash
# from the app repo
cd ../service-b
./scripts/build-and-push.sh 0.1.1

# from gitops
cd ../gitops
./scripts/bump-image-tag.sh service-b 0.1.1
git add apps/service-b/overlays/local/kustomization.yaml
git commit -m "Bump service-b image" && git push
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
(cd ../service-b && ./scripts/build-and-push.sh 0.1.1)
./scripts/bump-image-tag.sh service-b 0.1.1
git add apps/service-b/overlays/local/kustomization.yaml
git commit -m "Release service-b 0.1.1" && git push
# Watch sync in the Argo CD UI, or: kubectl -n argocd get applications
```

## Out of scope

Hosted CI/CD, Ingress, service-to-service auth.
