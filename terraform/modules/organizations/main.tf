# =============================================================================
# Module : organizations
# Crée l'organisation AWS, les unités organisationnelles (OU) et les comptes
# membres qui composent la Landing Zone multi-comptes.
# =============================================================================

# -----------------------------------------------------------------------------
# Organisation AWS
# Activée avec l'ensemble des fonctionnalités ("ALL") pour pouvoir attacher des
# Service Control Policies (SCP) et déléguer l'administration de services.
# -----------------------------------------------------------------------------
resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  # Services AWS autorisés à agir au niveau de l'organisation.
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
  ]

  # Types de politiques gérées au niveau de l'organisation.
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
}

# -----------------------------------------------------------------------------
# Unités organisationnelles (OU) de premier niveau
# -----------------------------------------------------------------------------
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Comptes de sécurité et de conformité (log-archive, audit)"
  })
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Comptes applicatifs (production, pré-production)"
  })
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Comptes d'expérimentation à garde-fous renforcés"
  })
}

# Sous-OU pour séparer prod et non-prod sous Workloads.
resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id

  tags = merge(var.tags, {
    Environment = "production"
  })
}

resource "aws_organizations_organizational_unit" "workloads_nonprod" {
  name      = "NonProd"
  parent_id = aws_organizations_organizational_unit.workloads.id

  tags = merge(var.tags, {
    Environment = "non-production"
  })
}

# -----------------------------------------------------------------------------
# Comptes membres
# Le compte de gestion (management) est celui depuis lequel ce module est
# appliqué ; il n'est donc pas (re)créé ici.
# -----------------------------------------------------------------------------
resource "aws_organizations_account" "log_archive" {
  name      = "log-archive"
  email     = var.log_archive_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  # Empêche Terraform de tenter de fermer le compte sur un "destroy".
  close_on_deletion          = false
  iam_user_access_to_billing = "DENY"

  tags = merge(var.tags, {
    AccountType = "log-archive"
    Criticality = "high"
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "security_audit" {
  name      = "security-audit"
  email     = var.security_audit_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  close_on_deletion          = false
  iam_user_access_to_billing = "DENY"

  tags = merge(var.tags, {
    AccountType = "security-audit"
    Criticality = "high"
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "workloads_prod" {
  name      = "workloads-prod"
  email     = var.workloads_prod_account_email
  parent_id = aws_organizations_organizational_unit.workloads_prod.id

  close_on_deletion          = false
  iam_user_access_to_billing = "DENY"

  tags = merge(var.tags, {
    AccountType = "workload"
    Environment = "production"
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "workloads_nonprod" {
  name      = "workloads-nonprod"
  email     = var.workloads_nonprod_account_email
  parent_id = aws_organizations_organizational_unit.workloads_nonprod.id

  close_on_deletion          = false
  iam_user_access_to_billing = "DENY"

  tags = merge(var.tags, {
    AccountType = "workload"
    Environment = "non-production"
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "sandbox" {
  name      = "sandbox"
  email     = var.sandbox_account_email
  parent_id = aws_organizations_organizational_unit.sandbox.id

  close_on_deletion          = false
  iam_user_access_to_billing = "DENY"

  tags = merge(var.tags, {
    AccountType = "sandbox"
    Environment = "sandbox"
  })

  lifecycle {
    ignore_changes = [role_name]
  }
}

# -----------------------------------------------------------------------------
# Délégation d'administration
# Le compte security-audit devient administrateur délégué de GuardDuty et
# Security Hub afin que le compte de gestion reste minimaliste.
# -----------------------------------------------------------------------------
resource "aws_organizations_delegated_administrator" "guardduty" {
  account_id        = aws_organizations_account.security_audit.id
  service_principal = "guardduty.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "securityhub" {
  account_id        = aws_organizations_account.security_audit.id
  service_principal = "securityhub.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = aws_organizations_account.security_audit.id
  service_principal = "config.amazonaws.com"
}
