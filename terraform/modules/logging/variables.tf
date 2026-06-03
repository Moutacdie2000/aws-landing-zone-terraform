# =============================================================================
# Variables du module logging
# =============================================================================

variable "log_bucket_name" {
  description = "Nom (globalement unique) du bucket S3 de logs centralisés."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.log_bucket_name))
    error_message = "Le nom du bucket doit respecter les contraintes S3 (3-63 caractères minuscules)."
  }
}

variable "trail_name" {
  description = "Nom de l'org-trail CloudTrail."
  type        = string
  default     = "org-cloudtrail"
}

variable "organization_id" {
  description = "Identifiant de l'organisation AWS (o-xxxxxxxxxx), utilisé dans la policy du bucket."
  type        = string
}

variable "management_account_id" {
  description = "Identifiant du compte de gestion (propriétaire de l'org-trail)."
  type        = string
}

variable "log_retention_days" {
  description = "Durée de rétention des logs avant expiration (en jours)."
  type        = number
  default     = 2555 # ~7 ans

  validation {
    condition     = var.log_retention_days >= 365
    error_message = "La rétention doit être d'au moins 365 jours pour des logs d'audit."
  }
}

variable "tags" {
  description = "Tags communs appliqués aux ressources de logging."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
