SHELL := /bin/bash
SCRIPTS := scripts

.PHONY: up down cluster-up cluster-down argocd-install argocd-apps wait sync-status \
	build-a build-b bump-a bump-b release-a release-b

up: cluster-up argocd-install argocd-apps wait
	@echo "Bootstrap complete. Port-forward example:"
	@echo "  kubectl -n demo port-forward svc/service-a 8080:8080"

down:
	@$(SCRIPTS)/cluster-down.sh

cluster-up:
	@$(SCRIPTS)/cluster-up.sh

cluster-down:
	@$(SCRIPTS)/cluster-down.sh

argocd-install:
	@$(SCRIPTS)/install-argocd.sh

argocd-apps:
	@$(SCRIPTS)/configure-argocd-repo.sh

wait:
	@$(SCRIPTS)/wait-argocd-sync.sh

sync-status:
	kubectl -n argocd get applications

# TAG=0.1.0 make release-b
# build-* calls sibling app scripts/build-and-push.sh; bump-* updates this repo's overlay.
build-a:
	@if [[ -z "$(TAG)" ]]; then echo "Usage: TAG=<immutable-tag> make build-a" >&2; exit 1; fi
	@source $(SCRIPTS)/env.sh && REGISTRY="$${REGISTRY}" "$${SERVICE_A_DIR}/scripts/build-and-push.sh" "$(TAG)"

build-b:
	@if [[ -z "$(TAG)" ]]; then echo "Usage: TAG=<immutable-tag> make build-b" >&2; exit 1; fi
	@source $(SCRIPTS)/env.sh && REGISTRY="$${REGISTRY}" "$${SERVICE_B_DIR}/scripts/build-and-push.sh" "$(TAG)"

bump-a:
	@$(SCRIPTS)/bump-image-tag.sh service-a "$(TAG)"

bump-b:
	@$(SCRIPTS)/bump-image-tag.sh service-b "$(TAG)"

release-a: build-a bump-a
	@echo "Commit apps/service-a/overlays/local/kustomization.yaml and push"

release-b: build-b bump-b
	@echo "Commit apps/service-b/overlays/local/kustomization.yaml and push"
