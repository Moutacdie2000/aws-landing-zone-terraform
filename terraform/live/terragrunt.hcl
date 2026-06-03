# =============================================================================
# Configuration racine Terragrunt
# Centralise le backend distant (state S3 + verrou DynamoDB) et la génération
# du bloc provider AWS pour rester DRY sur l'ensemble des modules "live".
# Chaque sous-dossier hérite de ce fichier via `include "root"`.
# =============================================================================

locals {
  # Variables globales partagées (déclinables par environnement si besoin).
  aws_region            = "eu-west-1"
  state_bucket          = "acme-landing-zone-tfstate"
  state_lock_table      = "acme-landing-zone-tflock"
  management_account_id = "111111111111"

  common_tags = {
    ManagedBy = "terragrunt"
    Project   = "aws-landing-zone"
    Owner     = "platform-team"
  }
}

# -----------------------------------------------------------------------------
# Backend distant : state chiffré dans S3, verrou via DynamoDB.
# La clé d'état est dérivée du chemin relatif du module pour éviter les
# collisions entre composants.
# -----------------------------------------------------------------------------
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = local.state_lock_table
  }
}

# -----------------------------------------------------------------------------
# Génération du provider AWS commun à tous les modules.
# -----------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      default_tags {
        tags = {
          ManagedBy = "terragrunt"
          Project   = "aws-landing-zone"
        }
      }
    }
  EOF
}

# -----------------------------------------------------------------------------
# Contraintes de version communes (Terraform + provider AWS).
# -----------------------------------------------------------------------------
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.6.0"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.40"
        }
      }
    }
  EOF
}

# Expose les locals racine aux configurations enfants via inputs hérités.
inputs = {
  management_account_id = local.management_account_id
  common_tags           = local.common_tags
}
