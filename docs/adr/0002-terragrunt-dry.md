# ADR 0002 — Terragrunt pour rester DRY et orchestrer les comptes

- **Statut** : Accepté
- **Date** : 2026-01-16
- **Décideurs** : Équipe plateforme cloud, Architecte AWS
- **Étiquettes** : iac, terraform, terragrunt, dry

## Contexte

Le socle déploie les mêmes modules Terraform à travers plusieurs comptes et
environnements (management, log-archive, security-audit, workloads, sandbox).
Avec du Terraform « brut », nous serions confrontés à :

- la **duplication** des blocs `backend "s3"` et `provider "aws"` dans chaque
  configuration racine (un par compte/composant) ;
- des **clés d'état** à maintenir manuellement, source d'erreurs et de
  collisions ;
- l'absence d'orchestration native des **dépendances entre composants** (ex. le
  module logging a besoin de l'`organization_id` produit par le module
  organizations) ;
- la difficulté d'exécuter une opération (`plan`/`apply`) **sur l'ensemble** du
  socle de façon ordonnée.

Nous cherchons un moyen d'appliquer le principe DRY (Don't Repeat Yourself) à la
configuration d'infrastructure sans réécrire les mêmes 30 lignes de backend et
de provider partout.

## Décision

Nous adoptons **Terragrunt** comme surcouche d'orchestration de Terraform.

Concrètement :

- Un **`terragrunt.hcl` racine** (`terraform/live/terragrunt.hcl`) centralise le
  `remote_state` (backend S3 + verrou DynamoDB) et **génère** les fichiers
  `provider.tf` et `versions.tf` via des blocs `generate`. La clé d'état est
  dérivée automatiquement via `path_relative_to_include()`.
- Chaque composant « live » (ex. `live/log-archive/logging/terragrunt.hcl`)
  contient un `include "root"` qui hérite de cette configuration, plus un bloc
  `terraform { source = "../../../modules//<module>" }` et ses `inputs`.
- Les **dépendances** entre composants sont déclarées avec des blocs
  `dependency`, avec `mock_outputs` pour permettre `validate`/`plan` hors ligne.
- L'orchestration globale se fait via `terragrunt run-all <commande>`, qui
  respecte le graphe de dépendances.

Les **modules** Terraform restent purs (aucune dépendance à Terragrunt), ce qui
les garde réutilisables et testables indépendamment.

## Conséquences

### Positives

- **Zéro duplication** du backend et du provider : définis une seule fois,
  hérités partout.
- **Clés d'état déterministes** : générées à partir du chemin, sans gestion
  manuelle ni risque de collision.
- **Dépendances explicites** : le branchement des sorties (organization_id,
  account_ids) est déclaratif et versionné.
- **Opérations à l'échelle** : `run-all plan/apply/destroy` pilote tout le socle
  dans le bon ordre.
- **Modules portables** : restant agnostiques de Terragrunt, ils peuvent être
  consommés par d'autres outils ou testés isolément.

### Négatives / coûts

- **Dépendance à un outil supplémentaire** : Terragrunt doit être installé et sa
  version épinglée (gérée dans la CI et les prérequis).
- **Indirection** : comprendre où sont générés `provider.tf`/`backend.tf`
  demande de connaître le mécanisme `generate`/`include`. Atténué par la
  documentation et des commentaires.
- **Couplage à la convention de chemins** : la structure `live/<compte>/<composant>`
  doit être respectée pour que les clés d'état restent cohérentes.

## Alternatives envisagées

- **Terraform brut + workspaces** — rejetée : les workspaces partagent la même
  configuration de backend et de provider et conviennent mal à des comptes AWS
  distincts ; la duplication du backend par composant subsiste.
- **Terraform brut + scripts maison (Makefile/bash) pour le backend** — rejetée :
  revient à réimplémenter en moins robuste ce que Terragrunt fournit nativement
  (génération, dépendances, run-all).
- **Terraform Cloud / Spacelift / Env0** — envisagée : plateformes SaaS de
  qualité, mais introduisent un coût et une dépendance externe non souhaités pour
  un socle de démonstration auto-hébergé. Terragrunt reste open source et local.
- **Module racine unique avec `for_each` sur les comptes** — rejetée : concentre
  tout l'état dans un seul backend, augmente le blast radius d'un `apply` et
  complique la délégation par compte.
