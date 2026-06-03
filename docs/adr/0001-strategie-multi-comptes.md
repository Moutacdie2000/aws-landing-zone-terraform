# ADR 0001, Stratégie multi-comptes plutôt qu'un compte unique

- **Statut** : Accepté
- **Date** : 2026-01-15
- **Décideurs** : Équipe plateforme cloud, Architecte AWS
- **Étiquettes** : gouvernance, sécurité, organisation

## Contexte

Nous démarrons la construction d'un socle d'atterrissage (Landing Zone) AWS qui
hébergera plusieurs équipes et environnements (production, non-production,
expérimentation). Nous devons décider de la topologie de comptes :

- **Option A** : un compte AWS unique, séparant les ressources par tags, VPC et
  politiques IAM.
- **Option B** : une organisation AWS multi-comptes, avec un compte par
  fonction/environnement, regroupés en unités organisationnelles (OU).

Plusieurs contraintes pèsent sur ce choix :

- Besoin d'**isolation forte** entre la production et le reste, pour limiter le
  blast radius d'une erreur ou d'une compromission.
- Exigence de **traçabilité** et d'immuabilité des logs d'audit (conformité).
- **Quotas de service** AWS appliqués par compte et par région (un compte unique
  devient vite un goulet d'étranglement).
- Volonté d'une **délégation d'administration** propre (sécurité vs FinOps vs
  applicatif) sans donner des droits trop larges.
- **Lisibilité de la facturation** par équipe et par environnement.

## Décision

Nous adoptons l'**option B : une organisation AWS multi-comptes**.

La topologie retenue est :

- Un **compte de gestion** (payer) minimaliste, hébergeant uniquement
  l'organisation, les SCP et IAM Identity Center.
- Une **OU Security** avec deux comptes : `log-archive` (coffre-fort de logs) et
  `security-audit` (administrateur délégué GuardDuty/Config/Security Hub).
- Une **OU Workloads** scindée en sous-OU `Prod` et `NonProd`, chacune avec son
  compte applicatif.
- Une **OU Sandbox** isolant l'expérimentation derrière des garde-fous renforcés.

Les frontières de comptes servent de premier mécanisme d'isolation ; les SCP
plafonnent les permissions par OU ; IAM Identity Center fournit l'accès fédéré.

## Conséquences

### Positives

- **Isolation par conception** : la frontière de compte est la limite de
  sécurité la plus forte d'AWS. Une compromission ou une erreur reste confinée à
  un compte.
- **Blast radius maîtrisé** : un quota atteint, une suppression accidentelle ou
  une fuite de credentials n'affecte qu'un compte.
- **Délégation propre** : la sécurité administre depuis `security-audit`, les
  logs sont isolés dans `log-archive`, sans surdroits dans le compte de gestion.
- **Garde-fous à l'échelle** : les SCP s'appliquent par OU, ce qui permet
  d'imposer des règles différenciées (sandbox plus stricte, par exemple).
- **Facturation lisible** : chaque compte est une ligne de coût naturelle, sans
  dépendre uniquement du tagging.

### Négatives / coûts

- **Complexité opérationnelle accrue** : gestion de plusieurs comptes, du
  routage inter-comptes et de l'accès fédéré. Atténuée par l'IaC (Terraform +
  Terragrunt) et IAM Identity Center.
- **Courbe d'apprentissage** : les équipes doivent comprendre le modèle
  d'organisation, les rôles et les OU.
- **Coûts marginaux** : certains services facturent par compte/région ; reste
  négligeable face aux bénéfices de sécurité.

## Alternatives envisagées

- **Compte unique avec isolation par IAM/VPC (option A)**, rejetée : l'isolation
  repose entièrement sur la justesse des politiques IAM, sans frontière dure ;
  les quotas deviennent bloquants ; la facturation par équipe est fragile ; et
  une compromission expose l'ensemble du périmètre.
- **AWS Control Tower clé en main**, envisagée puis écartée pour ce socle de
  démonstration : Control Tower automatise une partie de ce que nous mettons en
  place, mais nous souhaitons **maîtriser et exposer explicitement** chaque
  mécanisme (org-trail, SCP, délégation) en Terraform à des fins pédagogiques et
  de portabilité. Une migration vers Control Tower reste possible ultérieurement.
- **Comptes séparés sans OU**, rejetée : sans OU, les SCP devraient être
  attachées compte par compte, ce qui ne passe pas à l'échelle et nuit à la
  lisibilité de la gouvernance.
