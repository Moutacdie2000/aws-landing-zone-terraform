# =============================================================================
# Variables du module scp
# =============================================================================

variable "allowed_regions" {
  description = "Liste des régions AWS autorisées (toute autre région est refusée)."
  type        = list(string)
  default     = ["eu-west-1", "eu-west-3"]

  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "Au moins une région doit être autorisée."
  }
}

variable "log_bucket_name" {
  description = "Nom du bucket S3 de logs centralisés à protéger contre la suppression."
  type        = string
}

variable "protect_security_target_ids" {
  description = "Identifiants des OU/comptes ciblés par la SCP de protection des services de sécurité."
  type        = list(string)
}

variable "region_restriction_target_ids" {
  description = "Identifiants des OU/comptes ciblés par la SCP de restriction des régions."
  type        = list(string)
}

variable "deny_root_target_ids" {
  description = "Identifiants des OU/comptes ciblés par la SCP d'interdiction du root."
  type        = list(string)
}

variable "protect_log_bucket_target_ids" {
  description = "Identifiants des OU/comptes ciblés par la SCP de protection des buckets de logs."
  type        = list(string)
}

variable "tags" {
  description = "Tags communs appliqués aux politiques."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
