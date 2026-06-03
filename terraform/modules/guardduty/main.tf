# =============================================================================
# Module : guardduty
# Active Amazon GuardDuty au niveau de l'organisation. Ce module s'applique
# dans le compte administrateur délégué (security-audit) : il crée le
# détecteur, configure l'auto-activation des nouveaux comptes et enrôle les
# comptes membres existants.
# =============================================================================

# -----------------------------------------------------------------------------
# Détecteur GuardDuty du compte administrateur délégué.
# -----------------------------------------------------------------------------
resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Configuration de l'organisation : auto-activation des nouveaux comptes.
# -----------------------------------------------------------------------------
resource "aws_guardduty_organization_configuration" "this" {
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.this.id

  datasources {
    s3_logs {
      auto_enable = true
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          auto_enable = var.enable_malware_protection
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Enrôlement explicite des comptes membres existants.
# Les nouveaux comptes sont couverts par l'auto-activation ci-dessus ; cette
# ressource garantit que les comptes déjà présents sont également enrôlés.
# -----------------------------------------------------------------------------
resource "aws_guardduty_member" "this" {
  for_each = var.member_accounts

  detector_id                = aws_guardduty_detector.this.id
  account_id                 = each.value.account_id
  email                      = each.value.email
  invite                     = true
  disable_email_notification = true

  depends_on = [aws_guardduty_organization_configuration.this]
}
