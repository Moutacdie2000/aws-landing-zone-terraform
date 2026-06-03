# =============================================================================
# Variables du module guardduty
# =============================================================================

variable "finding_publishing_frequency" {
  description = "Fréquence de publication des findings vers CloudWatch Events/EventBridge."
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Valeurs autorisées : FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

variable "enable_kubernetes_protection" {
  description = "Active la protection des journaux d'audit Kubernetes (EKS)."
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Active la protection anti-malware par analyse des volumes EBS."
  type        = bool
  default     = true
}

variable "member_accounts" {
  description = <<-EOT
    Carte des comptes membres à enrôler explicitement.
    Clé : libellé logique du compte.
    Valeurs : account_id et email racine du compte.
  EOT
  type = map(object({
    account_id = string
    email      = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags communs appliqués au détecteur GuardDuty."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
