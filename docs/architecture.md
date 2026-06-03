# Architecture, Socle Landing Zone multi-comptes

Ce document décrit l'organisation AWS multi-comptes mise en place par ce socle,
ainsi que les flux de logs centralisés vers le compte `log-archive`.

## Vue d'ensemble de l'organisation

```mermaid
graph TD
    subgraph ORG["AWS Organization (feature_set = ALL)"]
        ROOT["Racine de l'organisation<br/>(r-xxxx)"]

        MGMT["Compte de gestion<br/>(management / payer)<br/>Org, SCP, Identity Center"]

        subgraph OU_SEC["OU : Security"]
            LOGS["Compte log-archive<br/>Bucket S3 logs + KMS<br/>(immuable, versionné)"]
            AUDIT["Compte security-audit<br/>Admin délégué :<br/>GuardDuty, Config, SecurityHub"]
        end

        subgraph OU_WL["OU : Workloads"]
            subgraph OU_PROD["OU : Prod"]
                WLPROD["Compte workloads-prod"]
            end
            subgraph OU_NP["OU : NonProd"]
                WLNP["Compte workloads-nonprod"]
            end
        end

        subgraph OU_SBX["OU : Sandbox"]
            SBX["Compte sandbox<br/>(garde-fous renforcés)"]
        end
    end

    ROOT --> MGMT
    ROOT --> OU_SEC
    ROOT --> OU_WL
    ROOT --> OU_SBX

    %% Garde-fous SCP appliqués depuis le compte de gestion
    MGMT -. "SCP : régions, root,<br/>protection sécurité & logs" .-> OU_WL
    MGMT -. "SCP" .-> OU_SBX
    MGMT -. "SCP" .-> OU_SEC

    classDef mgmt fill:#ff9900,stroke:#232f3e,color:#232f3e;
    classDef sec fill:#dd344c,stroke:#232f3e,color:#fff;
    classDef wl fill:#3b48cc,stroke:#232f3e,color:#fff;
    classDef sbx fill:#7aa116,stroke:#232f3e,color:#fff;

    class MGMT mgmt;
    class LOGS,AUDIT sec;
    class WLPROD,WLNP wl;
    class SBX sbx;
```

### Description des comptes

| Compte | OU | Rôle |
| --- | --- | --- |
| `management` | Racine | Compte payeur, héberge l'organisation, les SCP et IAM Identity Center. Surface d'attaque minimale : aucune charge applicative. |
| `log-archive` | Security | Coffre-fort des logs : bucket S3 chiffré KMS, versionné et protégé par SCP. Accès en écriture seule pour les services. |
| `security-audit` | Security | Administrateur délégué de GuardDuty, AWS Config et Security Hub. Console unique pour les équipes sécurité. |
| `workloads-prod` | Workloads/Prod | Charges de production, isolées dans leur propre frontière de facturation et de blast radius. |
| `workloads-nonprod` | Workloads/NonProd | Dev, test et pré-production. |
| `sandbox` | Sandbox | Expérimentation libre encadrée par des SCP plus strictes (régions, budgets). |

## Flux de logs centralisés

Tous les journaux d'audit convergent vers le compte `log-archive`, qui n'est
accessible en écriture que par les services AWS et jamais modifiable par les
équipes applicatives (garanti par SCP).

```mermaid
flowchart LR
    subgraph MEMBERS["Comptes membres (tous)"]
        ACT1["Activité API<br/>workloads-prod"]
        ACT2["Activité API<br/>workloads-nonprod"]
        ACT3["Activité API<br/>sandbox"]
        CFG1["Changements de config<br/>(AWS Config)"]
    end

    subgraph MGMT["Compte management"]
        CT["CloudTrail org-trail<br/>(multi-régions, validé)"]
    end

    subgraph AUDITACC["Compte security-audit"]
        GD["GuardDuty<br/>(admin délégué)"]
        SH["Security Hub<br/>(agrégation findings)"]
    end

    subgraph LOGACC["Compte log-archive"]
        KMS["Clé KMS<br/>(rotation activée)"]
        S3["Bucket S3 central<br/>cloudtrail/ + config/<br/>versionné + lifecycle"]
    end

    ACT1 --> CT
    ACT2 --> CT
    ACT3 --> CT
    CT -- "logs chiffrés KMS" --> S3
    CFG1 -- "snapshots + history" --> S3
    S3 -- "déchiffrement" --- KMS

    ACT1 -. "analyse comportementale" .-> GD
    ACT2 -.-> GD
    ACT3 -.-> GD
    GD --> SH

    classDef store fill:#1d8102,stroke:#232f3e,color:#fff;
    classDef trail fill:#ff9900,stroke:#232f3e,color:#232f3e;
    classDef threat fill:#dd344c,stroke:#232f3e,color:#fff;

    class S3,KMS store;
    class CT trail;
    class GD,SH threat;
```

### Explication des flux

1. **CloudTrail (org-trail)** : un unique trail créé dans le compte de gestion
   capture les événements de gestion **et** de données (S3, Lambda) de **tous**
   les comptes de l'organisation. Les fichiers sont chiffrés via une clé KMS du
   compte `log-archive` puis déposés sous le préfixe `cloudtrail/` du bucket
   central. La validation des fichiers de log (`enable_log_file_validation`)
   garantit leur intégrité.

2. **AWS Config** : dans chaque compte, l'enregistreur capture la configuration
   et l'historique des changements de toutes les ressources supportées, puis les
   livre sous le préfixe `config/` du même bucket central.

3. **Chiffrement & immuabilité** : la clé KMS a la rotation automatique activée.
   Le bucket est versionné, bloque tout accès public, refuse les connexions non
   TLS, et applique un cycle de vie (transition `STANDARD_IA` à 90 j, `GLACIER`
   à 180 j, expiration à ~7 ans). Une SCP empêche toute suppression du bucket ou
   de ses objets, y compris par un administrateur.

4. **GuardDuty & Security Hub** : le compte `security-audit` est administrateur
   délégué. GuardDuty analyse en continu les logs CloudTrail, VPC Flow Logs et
   DNS de tous les comptes ; les nouveaux comptes sont enrôlés automatiquement.
   Security Hub agrège les findings pour offrir une vue de conformité unique.

### Principe de séparation des privilèges

- Le **compte de gestion** ne porte aucune charge applicative : il sert
  uniquement à la gouvernance (organisation, SCP, SSO). Cela réduit
  drastiquement sa surface d'attaque.
- Le **stockage des logs** (log-archive) est séparé de leur **analyse**
  (security-audit), de sorte qu'une compromission de la console d'analyse ne
  permet pas d'altérer les preuves.
- Les **workloads** sont isolés par environnement, chaque compte constituant une
  frontière naturelle de blast radius, de quotas et de facturation.
