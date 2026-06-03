# =============================================================================
# Variables du module iam-identity-center
# =============================================================================

variable "account_assignments" {
  description = <<-EOT
    Carte des assignations d'accès. Chaque entrée associe un groupe à un
    permission set sur un compte cible.
    Clé : libellé unique de l'assignation.
    Valeurs :
      - group          : un de "platform-admins", "auditors", "finops"
      - permission_set : un de "AdministratorAccess", "ReadOnly", "Billing"
      - account_id     : identifiant du compte AWS cible
  EOT
  type = map(object({
    group          = string
    permission_set = string
    account_id     = string
  }))

  validation {
    condition = alltrue([
      for a in values(var.account_assignments) :
      contains(["AdministratorAccess", "ReadOnly", "Billing"], a.permission_set)
    ])
    error_message = "permission_set doit valoir AdministratorAccess, ReadOnly ou Billing."
  }

  validation {
    condition = alltrue([
      for a in values(var.account_assignments) :
      contains(["platform-admins", "auditors", "finops"], a.group)
    ])
    error_message = "group doit valoir platform-admins, auditors ou finops."
  }
}

variable "tags" {
  description = "Tags communs appliqués aux permission sets."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
