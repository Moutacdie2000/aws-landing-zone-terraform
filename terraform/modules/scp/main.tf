# =============================================================================
# Module : scp (Service Control Policies)
# Définit des garde-fous préventifs au niveau de l'organisation. Les SCP ne
# accordent jamais de droits : elles plafonnent les permissions maximales
# possibles pour les comptes ciblés.
# =============================================================================

# -----------------------------------------------------------------------------
# SCP 1, Protéger les services de sécurité
# Interdit de désactiver ou d'altérer CloudTrail, GuardDuty, AWS Config et
# Security Hub, quel que soit l'utilisateur.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "protect_security_services" {
  statement {
    sid    = "DenyDisableCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyDisableGuardDuty"
    effect = "Deny"
    actions = [
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:DisassociateMembers",
      "guardduty:StopMonitoringMembers",
      "guardduty:UpdateDetector",
      "guardduty:DeleteMembers",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyDisableConfig"
    effect = "Deny"
    actions = [
      "config:DeleteConfigurationRecorder",
      "config:StopConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:DeleteConfigRule",
      "config:DeleteOrganizationConfigRule",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyDisableSecurityHub"
    effect = "Deny"
    actions = [
      "securityhub:DisableSecurityHub",
      "securityhub:DeleteMembers",
      "securityhub:DisassociateMembers",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_security_services" {
  name        = "deny-disable-security-services"
  description = "Empêche la désactivation de CloudTrail, GuardDuty, Config et Security Hub."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_security_services.json

  tags = var.tags
}

# -----------------------------------------------------------------------------
# SCP 2, Restreindre les régions autorisées
# Refuse toute action en dehors des régions approuvées. Les services globaux
# (IAM, Organizations, CloudFront, Route 53, Support…) sont explicitement
# exclus du refus car ils s'opèrent dans us-east-1.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "region_restriction" {
  statement {
    sid       = "DenyOutsideAllowedRegions"
    effect    = "Deny"
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }

    # NotAction : le refus s'applique à TOUTES les actions SAUF celles des
    # services globaux ci-dessous (qui s'opèrent dans us-east-1). Un statement
    # IAM ne peut pas combiner "actions" et "not_actions" : on n'utilise donc
    # que not_actions ici.
    not_actions = [
      "a4b:*",
      "access-analyzer:*",
      "account:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "budgets:*",
      "ce:*",
      "chime:*",
      "cloudfront:*",
      "globalaccelerator:*",
      "health:*",
      "iam:*",
      "kms:*",
      "organizations:*",
      "route53:*",
      "route53domains:*",
      "shield:*",
      "sts:*",
      "support:*",
      "trustedadvisor:*",
      "waf:*",
      "wafv2:*",
      "waf-regional:*",
    ]
  }
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "restrict-allowed-regions"
  description = "Refuse les actions hors des régions ${join(", ", var.allowed_regions)}."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.region_restriction.json

  tags = var.tags
}

# -----------------------------------------------------------------------------
# SCP 3, Interdire l'usage de l'utilisateur root
# Bloque toute action effectuée avec les identifiants root des comptes membres
# (sauf le compte de gestion, non ciblé par cette SCP).
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "deny_root_user" {
  statement {
    sid       = "DenyRootUserActions"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

resource "aws_organizations_policy" "deny_root_user" {
  name        = "deny-root-user"
  description = "Interdit toute action réalisée avec l'utilisateur root."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_root_user.json

  tags = var.tags
}

# -----------------------------------------------------------------------------
# SCP 4, Protéger les buckets de logs
# Refuse la suppression des buckets de logs et de leurs objets, ainsi que
# l'affaiblissement de leur chiffrement ou de leur configuration.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "protect_log_buckets" {
  statement {
    sid    = "DenyDeleteLogBuckets"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
    ]
    resources = [
      "arn:aws:s3:::${var.log_bucket_name}",
      "arn:aws:s3:::${var.log_bucket_name}/*",
    ]
  }
}

resource "aws_organizations_policy" "protect_log_buckets" {
  name        = "deny-delete-log-buckets"
  description = "Refuse la suppression et l'altération des buckets de logs centralisés."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_log_buckets.json

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Attachements des SCP aux cibles (OU ou comptes)
# -----------------------------------------------------------------------------

# Les protections de sécurité s'appliquent à toutes les OU concernées.
resource "aws_organizations_policy_attachment" "protect_security_services" {
  for_each  = toset(var.protect_security_target_ids)
  policy_id = aws_organizations_policy.protect_security_services.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "region_restriction" {
  for_each  = toset(var.region_restriction_target_ids)
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "deny_root_user" {
  for_each  = toset(var.deny_root_target_ids)
  policy_id = aws_organizations_policy.deny_root_user.id
  target_id = each.value
}

resource "aws_organizations_policy_attachment" "protect_log_buckets" {
  for_each  = toset(var.protect_log_bucket_target_ids)
  policy_id = aws_organizations_policy.protect_log_buckets.id
  target_id = each.value
}
