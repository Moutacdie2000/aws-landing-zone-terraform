# =============================================================================
# Module : iam-identity-center
# Configure les permission sets et les assignations d'accès via AWS IAM
# Identity Center (anciennement AWS SSO). L'instance Identity Center doit avoir
# été activée au préalable dans le compte de gestion.
# =============================================================================

# -----------------------------------------------------------------------------
# Récupération de l'instance Identity Center existante.
# -----------------------------------------------------------------------------
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

# -----------------------------------------------------------------------------
# Permission set : AdministratorAccess
# Accès administrateur complet, session courte (1 h) pour limiter l'exposition.
# -----------------------------------------------------------------------------
resource "aws_ssoadmin_permission_set" "administrator" {
  name             = "AdministratorAccess"
  description      = "Accès administrateur complet (sessions courtes)."
  instance_arn     = local.instance_arn
  session_duration = "PT1H"

  tags = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
}

# -----------------------------------------------------------------------------
# Permission set : ReadOnly
# Lecture seule sur l'ensemble des services, session de 4 h.
# -----------------------------------------------------------------------------
resource "aws_ssoadmin_permission_set" "read_only" {
  name             = "ReadOnly"
  description      = "Accès en lecture seule à tous les services."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"

  tags = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}

# -----------------------------------------------------------------------------
# Permission set : Billing
# Accès à la facturation et aux coûts, plus une lecture seule globale.
# -----------------------------------------------------------------------------
resource "aws_ssoadmin_permission_set" "billing" {
  name             = "Billing"
  description      = "Accès à la facturation, aux budgets et au cost management."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"

  tags = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "billing_managed" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "billing_readonly" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
}

# Politique inline restreignant le permission set Billing à ses seules actions.
data "aws_iam_policy_document" "billing_inline" {
  statement {
    sid    = "AllowCostAndUsage"
    effect = "Allow"
    actions = [
      "ce:Get*",
      "ce:List*",
      "ce:Describe*",
      "budgets:ViewBudget",
      "budgets:Describe*",
      "cur:Describe*",
      "cur:GetUsageReport",
    ]
    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "billing" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
  inline_policy      = data.aws_iam_policy_document.billing_inline.json
}

# -----------------------------------------------------------------------------
# Groupes Identity Center
# Créés dans l'Identity Store (source d'identité interne). En entreprise, ils
# proviendraient généralement d'un IdP externe (Entra ID, Okta) via SCIM.
# -----------------------------------------------------------------------------
resource "aws_identitystore_group" "platform_admins" {
  identity_store_id = local.identity_store_id
  display_name      = "platform-admins"
  description       = "Administrateurs de la plateforme cloud."
}

resource "aws_identitystore_group" "auditors" {
  identity_store_id = local.identity_store_id
  display_name      = "auditors"
  description       = "Auditeurs en lecture seule."
}

resource "aws_identitystore_group" "finops" {
  identity_store_id = local.identity_store_id
  display_name      = "finops"
  description       = "Équipe FinOps (gestion des coûts)."
}

# -----------------------------------------------------------------------------
# Assignations de comptes
# On itère sur une carte d'assignations fournie en variable pour rester DRY.
# -----------------------------------------------------------------------------
locals {
  permission_set_arns = {
    AdministratorAccess = aws_ssoadmin_permission_set.administrator.arn
    ReadOnly            = aws_ssoadmin_permission_set.read_only.arn
    Billing             = aws_ssoadmin_permission_set.billing.arn
  }

  group_ids = {
    "platform-admins" = aws_identitystore_group.platform_admins.group_id
    "auditors"        = aws_identitystore_group.auditors.group_id
    "finops"          = aws_identitystore_group.finops.group_id
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.account_assignments

  instance_arn       = local.instance_arn
  permission_set_arn = local.permission_set_arns[each.value.permission_set]

  principal_id   = local.group_ids[each.value.group]
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
