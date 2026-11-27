SHELL := /bin/bash
SCRIPTS := scripts

.PHONY: up down cluster-up cluster-down argocd-install argocd-apps wait sync-status \
	build-a build-b push-a push-b bump-a bump-b release-a release-b

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
# build-* delegates to sibling app scripts/build-and-push.sh; bump-* updates this repo's overlay.
build-a:
	@$(SCRIPTS)/build-and-push.sh service-a "$(TAG)"

build-b:
	@$(SCRIPTS)/build-and-push.sh service-b "$(TAG)"

bump-a:
	@$(SCRIPTS)/bump-image-tag.sh service-a "$(TAG)"

bump-b:
	@$(SCRIPTS)/bump-image-tag.sh service-b "$(TAG)"

release-a: build-a bump-a
	@echo "Commit apps/service-a/overlays/local/kustomization.yaml and push"

release-b: build-b bump-b
	@echo "Commit apps/service-b/overlays/local/kustomization.yaml and push"
