# =============================================================================
# Variables du module organizations
# =============================================================================

variable "log_archive_account_email" {
  description = "Adresse e-mail racine (unique) du compte log-archive."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.log_archive_account_email))
    error_message = "L'adresse e-mail du compte log-archive doit être valide."
  }
}

variable "security_audit_account_email" {
  description = "Adresse e-mail racine (unique) du compte security-audit."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.security_audit_account_email))
    error_message = "L'adresse e-mail du compte security-audit doit être valide."
  }
}

variable "workloads_prod_account_email" {
  description = "Adresse e-mail racine (unique) du compte workloads-prod."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.workloads_prod_account_email))
    error_message = "L'adresse e-mail du compte workloads-prod doit être valide."
  }
}

variable "workloads_nonprod_account_email" {
  description = "Adresse e-mail racine (unique) du compte workloads-nonprod."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.workloads_nonprod_account_email))
    error_message = "L'adresse e-mail du compte workloads-nonprod doit être valide."
  }
}

variable "sandbox_account_email" {
  description = "Adresse e-mail racine (unique) du compte sandbox."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.sandbox_account_email))
    error_message = "L'adresse e-mail du compte sandbox doit être valide."
  }
}

variable "tags" {
  description = "Tags communs appliqués aux ressources de l'organisation."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
