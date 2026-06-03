# =============================================================================
# Makefile — Socle Landing Zone multi-comptes
# Cibles utilitaires pour piloter Terragrunt/Terraform localement.
# Usage : make <cible>  (ex. make plan)
# =============================================================================

# Répertoire racine des configurations "live".
LIVE_DIR        := terraform/live
MODULES_DIR     := terraform/modules
TG              := terragrunt
TG_FLAGS        := --terragrunt-non-interactive

# Couleurs pour l'affichage.
CYAN  := \033[36m
RESET := \033[0m

.DEFAULT_GOAL := help
.PHONY: help fmt validate plan apply destroy lint security-scan init clean

## help : Affiche la liste des cibles disponibles.
help:
	@echo "Cibles disponibles :"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed -e 's/## /  /' | awk -F ' : ' '{printf "$(CYAN)%-16s$(RESET) %s\n", $$1, $$2}'

## fmt : Reformate récursivement tout le code HCL/Terraform.
fmt:
	@echo ">> Formatage du code Terraform/HCL"
	terraform fmt -recursive .
	$(TG) hclfmt

## init : Initialise tous les modules live (run-all init).
init:
	@echo ">> Initialisation Terragrunt (run-all)"
	cd $(LIVE_DIR) && $(TG) run-all init $(TG_FLAGS)

## validate : Valide la syntaxe et la cohérence de tous les modules.
validate:
	@echo ">> Validation des modules"
	cd $(LIVE_DIR) && $(TG) run-all validate $(TG_FLAGS)

## plan : Produit le plan d'exécution de l'ensemble du socle.
plan:
	@echo ">> Plan Terragrunt (run-all)"
	cd $(LIVE_DIR) && $(TG) run-all plan $(TG_FLAGS)

## apply : Applique l'ensemble du socle (respecte les dépendances).
apply:
	@echo ">> Apply Terragrunt (run-all)"
	cd $(LIVE_DIR) && $(TG) run-all apply $(TG_FLAGS)

## destroy : Détruit l'ensemble du socle. ATTENTION : opération destructrice.
destroy:
	@echo ">> Destruction Terragrunt (run-all)"
	@echo "ATTENTION : cette opération supprime les ressources de la Landing Zone."
	cd $(LIVE_DIR) && $(TG) run-all destroy $(TG_FLAGS)

## lint : Exécute tflint sur chaque module.
lint:
	@echo ">> Lint (tflint)"
	@tflint --init
	@for module in $(MODULES_DIR)/*/ ; do \
		echo "  -> $$module" ; \
		tflint --chdir="$$module" --format compact || exit 1 ; \
	done

## security-scan : Analyse de sécurité statique avec tfsec.
security-scan:
	@echo ">> Scan de sécurité (tfsec)"
	tfsec terraform --concise-output

## clean : Supprime les artefacts locaux (.terragrunt-cache, plans).
clean:
	@echo ">> Nettoyage des artefacts locaux"
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} +
	find . -type d -name ".terraform" -prune -exec rm -rf {} +
	find . -type f -name "*.tfplan" -delete
	find . -type f -name "plan_output.txt" -delete
