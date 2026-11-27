SHELL := /bin/bash
SCRIPTS := scripts

.PHONY: up down cluster-up cluster-down argocd-install argocd-apps sync-status \
	bump-a bump-b

up: cluster-up argocd-install argocd-apps
	@echo "Bootstrap complete. Check sync in the Argo CD UI, or:"
	@echo "  make sync-status"
	@echo "Port-forward UI: kubectl -n argocd port-forward svc/argocd-server 8081:443"
	@echo "Port-forward app: kubectl -n demo port-forward svc/service-a 8080:8080"

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

sync-status:
	kubectl -n argocd get applications

# TAG=0.1.0 make bump-b  — after building/pushing the image from the app repo
bump-a:
	@$(SCRIPTS)/bump-image-tag.sh service-a "$(TAG)"

bump-b:
	@$(SCRIPTS)/bump-image-tag.sh service-b "$(TAG)"
