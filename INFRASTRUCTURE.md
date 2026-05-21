# DIGITRANS-CM Infrastructure Documentation

## Architecture Cloud Hybride

### Vue d'ensemble

L'infrastructure DIGITRANS-CM est déployée sur une architecture cloud hybride combinant:
- **AWS (Amazon Web Services)** - Région: Cape Town (af-south-1) pour la souveraineté des données
- **Azure (Microsoft Azure)** - Région: South Africa North pour l'identité et la supervision

### Justification des choix architecturaux

#### 1. Régions Cloud Africaines
- **AWS Cape Town (af-south-1)**: Latence optimale (~50-80ms depuis Douala), conformité RGPD/loi camerounaise n°2010/012
- **Azure South Africa North**: Intégration Azure AD pour IAM centralisé, Log Analytics pour supervision multi-cloud

#### 2. Architecture Résiliente
- **Multi-AZ**: Déploiement sur 2 zones de disponibilité (af-south-1a, af-south-1b)
- **Auto-scaling**: HPA Kubernetes avec seuils CPU 70%, mémoire 80%
- **Load Balancing**: ALB AWS + Kubernetes Service LoadBalancer
- **Offline-first**: Redis ElastiCache avec TTL 60s (opérationnel) / 300s (BI)

#### 3. Sécurité
- **Chiffrement**: TLS 1.2+ en transit, AES-256 au repos (RDS, S3, ElastiCache)
- **IAM**: Azure AD avec groupes RBAC (Admins, Managers, Agents, Viewers)
- **Secrets**: Azure Key Vault + Kubernetes Secrets
- **Network**: VPC isolé, sous-réseaux privés pour DB, Security Groups restrictifs

---

## Composants Infrastructure

### AWS Resources

#### Réseau (VPC)
```
VPC: 10.0.0.0/16
├── Public Subnets
│   ├── 10.0.1.0/24 (af-south-1a) - ALB, NAT Gateway
│   └── 10.0.2.0/24 (af-south-1b) - ALB
├── Private Subnets
│   ├── 10.0.10.0/24 (af-south-1a) - RDS, ElastiCache, EKS Nodes
│   └── 10.0.11.0/24 (af-south-1b) - RDS, ElastiCache, EKS Nodes
```

#### Bases de données (RDS MySQL 8.0)
- **erp_db**: db.t3.medium (prod), Multi-AZ, 20GB, backup 7j
- **crm_db**: db.t3.medium (prod), Multi-AZ, 20GB, backup 7j
- **supply_db**: db.t3.medium (prod), Multi-AZ, 20GB, backup 7j
- **Chiffrement**: Activé (AES-256)
- **Rotation clés**: Automatique tous les 90 jours

#### Cache (ElastiCache Redis 7.0)
- **Type**: cache.t3.medium (prod), 2 nœuds
- **Réplication**: Automatique avec failover
- **Chiffrement**: Transit + repos activé
- **Usage**: Cache applicatif (60s), sessions utilisateur

#### Stockage (S3)
- **Bucket**: digitrans-cm-assets-prod-{account_id}
- **Versioning**: Activé
- **Chiffrement**: SSE-AES256
- **Accès**: Privé (Block Public Access)

#### Orchestration (EKS 1.28)
- **Cluster**: digitrans-cm-eks-prod
- **Node Group**: 2-6 nœuds t3.medium (auto-scaling)
- **Namespace**: digitrans-cm
- **Services**: 5 microservices + Redis + RabbitMQ

#### Monitoring (CloudWatch)
- **Logs**: Rétention 30j (prod), 7j (dev/test)
- **Métriques**: RDS CPU/Storage, ALB latence/erreurs, ElastiCache
- **Alarmes**: SNS vers ops@camtechsolutions.cm
- **Dashboard**: Vue consolidée temps réel

### Azure Resources

#### Identité (Azure AD)
- **Groupes**:
  - DIGITRANS-CM-Admins-prod (accès complet)
  - DIGITRANS-CM-Managers-prod (lecture/écriture métier)
  - DIGITRANS-CM-Agents-prod (lecture/écriture terrain)
  - DIGITRANS-CM-Viewers-prod (lecture seule)

#### Secrets (Key Vault)
- **Nom**: digitrans-cm-kv-prod
- **Secrets stockés**: db-username, jwt-secret, api-keys
- **Accès**: RBAC (Admins = Administrator, Managers = Secrets User)
- **Rotation**: Manuelle (recommandé: automatique via Azure Functions)

#### Supervision (Log Analytics + Application Insights)
- **Workspace**: digitrans-cm-logs-prod (rétention 30j)
- **App Insights**: digitrans-cm-appinsights-prod
- **Métriques**: Temps réponse, taux erreur, disponibilité
- **Alertes**: Email + SMS vers équipe ops

#### Backup (Storage Account)
- **Nom**: digitranscmbackupprod
- **Type**: GRS (Geo-Redundant Storage)
- **Container**: database-backups
- **Rétention**: 30 jours

---

## Déploiement Infrastructure

### Prérequis
```bash
# Outils requis
terraform >= 1.5
aws-cli >= 2.0
azure-cli >= 2.50
kubectl >= 1.28
```

### 1. Déploiement AWS (Terraform)

```bash
cd terraform/aws

# Initialiser Terraform
terraform init

# Créer le fichier terraform.tfvars
cat > terraform.tfvars <<EOF
environment = "prod"
aws_region  = "af-south-1"
vpc_cidr    = "10.0.0.0/16"
db_username = "admin"
db_password = "SECURE_PASSWORD_HERE"
EOF

# Planifier les changements
terraform plan -out=tfplan

# Appliquer l'infrastructure
terraform apply tfplan

# Récupérer les outputs
terraform output -json > outputs.json
```

### 2. Déploiement Azure (Terraform)

```bash
cd terraform/azure

# Login Azure
az login

# Initialiser Terraform
terraform init

# Créer le fichier terraform.tfvars
cat > terraform.tfvars <<EOF
environment = "prod"
azure_region = "southafricanorth"
admin_group_members = ["admin@camtechsolutions.cm"]
EOF

# Appliquer l'infrastructure
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Configuration EKS

```bash
# Mettre à jour kubeconfig
aws eks update-kubeconfig --name digitrans-cm-eks-prod --region af-south-1

# Créer le namespace et secrets
kubectl apply -f k8s/00-namespace.yaml

# Mettre à jour les secrets avec les valeurs réelles
kubectl create secret generic digitrans-cm-secrets \
  --from-literal=JWT_SECRET='agrocam-digitrans-secret-key-2024-very-long-secret' \
  --from-literal=DB_USER='admin' \
  --from-literal=DB_PASS='SECURE_PASSWORD' \
  --from-literal=RABBITMQ_PASS='guest' \
  -n digitrans-cm --dry-run=client -o yaml | kubectl apply -f -

# Déployer Redis et RabbitMQ
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/rabbitmq-deployment.yaml

# Attendre que Redis et RabbitMQ soient prêts
kubectl wait --for=condition=ready pod -l app=redis -n digitrans-cm --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n digitrans-cm --timeout=300s

# Déployer les microservices (après build CI/CD)
kubectl apply -f k8s/erp-service-deployment.yaml
kubectl apply -f k8s/crm-service-deployment.yaml
kubectl apply -f k8s/supply-chain-service-deployment.yaml
kubectl apply -f k8s/bi-service-deployment.yaml
kubectl apply -f k8s/api-gateway-deployment.yaml
```

---

## Pipeline CI/CD

### GitHub Actions Workflow

Le pipeline automatise:
1. **Build & Test**: Compilation Maven, tests unitaires
2. **Security Scan**: Trivy pour vulnérabilités
3. **Docker Build**: Construction images + push ECR
4. **Deploy EKS**: Déploiement Kubernetes avec rolling update
5. **Performance Test**: Tests de charge k6
6. **Notification**: Slack/Email

### Secrets GitHub requis
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
SLACK_WEBHOOK_URL
API_GATEWAY_URL
```

### Déclenchement
- **Push main**: Déploiement production
- **Push develop**: Déploiement test
- **Pull Request**: Build + tests uniquement

---

## Gestion des Environnements

### Séparation stricte

| Environnement | AWS Account | VPC CIDR | RDS Instance | EKS Nodes |
|---------------|-------------|----------|--------------|-----------|
| dev | 111111111111 | 10.1.0.0/16 | db.t3.micro | 2x t3.small |
| test | 222222222222 | 10.2.0.0/16 | db.t3.small | 2x t3.small |
| prod | 333333333333 | 10.0.0.0/16 | db.t3.medium | 2-6x t3.medium |

### Variables d'environnement

Chaque environnement a son propre:
- Fichier `terraform.tfvars`
- Backend S3 séparé
- Namespace Kubernetes dédié
- Secrets isolés

---

## Monitoring & Alertes

### Métriques clés (KPI)

#### Disponibilité
- **Cible**: 99.9% (SLA)
- **Mesure**: CloudWatch Synthetics + Application Insights
- **Alerte**: < 99.5% sur 5 minutes

#### Performance
- **Latence API**: < 500ms (P95)
- **Temps réponse DB**: < 100ms (P95)
- **Throughput**: > 1000 req/s

#### Ressources
- **CPU**: < 70% (moyenne)
- **Mémoire**: < 80% (moyenne)
- **Stockage DB**: > 20% libre

### Dashboards

#### CloudWatch Dashboard
- Vue temps réel: RDS, ALB, ElastiCache, EKS
- URL: https://console.aws.amazon.com/cloudwatch/dashboards/digitrans-cm-prod

#### Azure Monitor Dashboard
- Vue applicative: Temps réponse, erreurs, dépendances
- URL: https://portal.azure.com (Application Insights)

---

## Optimisation des Coûts

### Stratégies implémentées

#### 1. Auto-scaling
- **EKS Nodes**: Scale down hors heures de pointe (22h-6h)
- **RDS**: Arrêt automatique environnements dev/test le week-end
- **ElastiCache**: Instance type adapté à la charge

#### 2. Reserved Instances
- **RDS**: RI 1 an pour prod (économie ~40%)
- **EC2**: Savings Plans pour EKS nodes (économie ~30%)

#### 3. Lifecycle Policies
- **S3**: Transition vers Glacier après 90j
- **CloudWatch Logs**: Rétention 7j (dev), 30j (prod)
- **RDS Snapshots**: Suppression automatique > 30j

#### 4. Monitoring Coûts
- **AWS Cost Explorer**: Alertes > 500 USD/mois
- **Azure Cost Management**: Alertes > 200 USD/mois
- **Tags**: Traçabilité par service/environnement

### Budget mensuel estimé (prod)

| Service | Coût mensuel (USD) |
|---------|-------------------|
| EKS (3 nodes t3.medium) | ~220 |
| RDS (3x db.t3.medium Multi-AZ) | ~450 |
| ElastiCache (2 nodes cache.t3.medium) | ~180 |
| ALB | ~25 |
| S3 + Data Transfer | ~50 |
| CloudWatch | ~30 |
| Azure (Key Vault + Monitor) | ~100 |
| **Total** | **~1055 USD/mois** |

---

## Sécurité & Conformité

### Chiffrement

#### En transit
- TLS 1.2+ pour toutes les communications
- Certificats ACM (AWS Certificate Manager)
- Azure Key Vault pour gestion certificats

#### Au repos
- RDS: Chiffrement AES-256 activé
- S3: SSE-AES256
- ElastiCache: Chiffrement activé
- EBS volumes: Chiffrement par défaut

### Rotation des secrets

#### Automatique
- RDS master password: 90 jours (AWS Secrets Manager)
- Azure Key Vault secrets: 90 jours (Azure Functions)

#### Manuelle
- JWT secret: Annuel
- API keys: Semestriel

### Audit & Traçabilité

#### AWS CloudTrail
- Tous les appels API AWS loggés
- Rétention: 90 jours
- Stockage: S3 bucket dédié

#### Azure Activity Log
- Tous les changements Azure AD/Key Vault
- Rétention: 90 jours
- Export vers Log Analytics

---

## Procédures Opérationnelles

### Backup & Restore

#### RDS
```bash
# Backup manuel
aws rds create-db-snapshot \
  --db-instance-identifier digitrans-cm-erp-prod \
  --db-snapshot-identifier erp-manual-$(date +%Y%m%d)

# Restore
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier digitrans-cm-erp-restored \
  --db-snapshot-identifier erp-manual-20260115
```

#### Kubernetes
```bash
# Backup avec Velero
velero backup create digitrans-cm-backup-$(date +%Y%m%d) \
  --include-namespaces digitrans-cm

# Restore
velero restore create --from-backup digitrans-cm-backup-20260115
```

### Incident Response

#### 1. Détection
- Alertes CloudWatch/Azure Monitor
- Notification SNS/Email/SMS

#### 2. Triage
- Vérifier dashboards
- Consulter logs (CloudWatch Insights, Log Analytics)

#### 3. Mitigation
- Rollback Kubernetes: `kubectl rollout undo deployment/SERVICE -n digitrans-cm`
- Scale up: `kubectl scale deployment/SERVICE --replicas=6 -n digitrans-cm`

#### 4. Post-mortem
- Document incident dans Confluence
- Mise à jour runbooks

---

## Contacts & Support

| Rôle | Contact | Disponibilité |
|------|---------|---------------|
| Ops Team | ops@camtechsolutions.cm | 24/7 |
| DevOps Lead | devops-lead@camtechsolutions.cm | Lun-Ven 8h-18h |
| AWS Support | Enterprise Support | 24/7 |
| Azure Support | Professional Direct | 24/7 |

---

## Références

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Loi camerounaise n°2010/012 (Cybersécurité)](https://www.cert.cm/reglementation/)
