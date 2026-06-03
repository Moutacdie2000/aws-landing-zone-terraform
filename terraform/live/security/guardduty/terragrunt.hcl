# =============================================================================
# Live : compte security-audit, composant guardduty
# Appelle le module guardduty depuis le compte administrateur délégué afin
# d'activer GuardDuty pour toute l'organisation.
# =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//guardduty"
}

# Dépend des sorties de l'organisation pour récupérer la liste des comptes
# membres à enrôler.
dependency "organizations" {
  config_path = "../../management/organizations"

  mock_outputs = {
    account_ids = {
      log_archive       = "222222222222"
      workloads_prod    = "333333333333"
      workloads_nonprod = "444444444444"
      sandbox           = "555555555555"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_kubernetes_protection = true
  enable_malware_protection    = true

  # Enrôlement explicite des comptes membres existants.
  member_accounts = {
    log_archive = {
      account_id = dependency.organizations.outputs.account_ids.log_archive
      email      = "aws+log-archive@acme.example"
    }
    workloads_prod = {
      account_id = dependency.organizations.outputs.account_ids.workloads_prod
      email      = "aws+workloads-prod@acme.example"
    }
    workloads_nonprod = {
      account_id = dependency.organizations.outputs.account_ids.workloads_nonprod
      email      = "aws+workloads-nonprod@acme.example"
    }
    sandbox = {
      account_id = dependency.organizations.outputs.account_ids.sandbox
      email      = "aws+sandbox@acme.example"
    }
  }

  tags = {
    ManagedBy = "terragrunt"
    Project   = "aws-landing-zone"
    Account   = "security-audit"
    Component = "guardduty"
  }
}
