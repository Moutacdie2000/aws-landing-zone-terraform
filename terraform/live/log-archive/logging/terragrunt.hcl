# =============================================================================
# Live : compte log-archive — composant logging
# Appelle le module logging pour provisionner le bucket S3 chiffré,
# l'org-trail CloudTrail et AWS Config dans le compte log-archive.
# =============================================================================

# Hérite du backend distant et du provider générés par la racine.
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//logging"
}

# Récupère les sorties de l'organisation (IDs de compte, organization_id) pour
# brancher les dépendances sans coder en dur les identifiants.
dependency "organizations" {
  config_path = "../../management/organizations"

  # Valeurs simulées pour permettre `plan`/`validate` avant que l'organisation
  # ne soit réellement déployée.
  mock_outputs = {
    organization_id        = "o-mock1234567"
    management_account_id  = "111111111111"
    log_archive_account_id = "222222222222"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  log_bucket_name       = "acme-org-central-logs"
  trail_name            = "org-cloudtrail"
  organization_id       = dependency.organizations.outputs.organization_id
  management_account_id = dependency.organizations.outputs.management_account_id
  log_retention_days    = 2555

  tags = {
    ManagedBy = "terragrunt"
    Project   = "aws-landing-zone"
    Account   = "log-archive"
    Component = "logging"
  }
}
