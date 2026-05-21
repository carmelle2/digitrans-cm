# DIGITRANS-CM - Projet Complet

## 📋 Vue d'ensemble

**Projet:** DIGITRANS-CM (Digitalisation et Transformation Numérique au Cameroun)  
**Client:** AGROCAM S.A.  
**Prestataire:** CAMTECH SOLUTIONS S.A.  
**Contexte:** Examen Semestre 2 - Cloud Computing (EADL 4)

---

## 🏗️ Architecture

### Application (Spring Boot 3.2 + Java 17)

**5 Microservices:**
1. **api-gateway** (8080) - Spring Cloud Gateway, routage, JWT validation
2. **erp-service** (8081) - Employees, Suppliers, Accounting + Auth JWT
3. **crm-service** (8082) - Customers, Orders, Restaurants
4. **supply-chain-service** (8083) - Products, Shipments, Checkpoints + RabbitMQ publisher
5. **bi-service** (8084) - Dashboard, Stats, Revenue (queries multi-DB)

**Infrastructure:**
- MySQL 8.0 (4 bases: erp_db, crm_db, supply_db, bi_db)
- Redis 7.0 (cache offline-first, TTL 60s/300s)
- RabbitMQ 3.12 (messaging async)

### Cloud Hybride (AWS + Azure)

**AWS (Cape Town - af-south-1):**
- VPC 10.0.0.0/16 (2 AZs, public/private subnets)
- RDS MySQL Multi-AZ (3 instances db.t3.medium)
- ElastiCache Redis (2 nodes cache.t3.medium)
- EKS 1.28 (2-6 nodes t3.medium auto-scaling)
- ALB + S3 + CloudWatch

**Azure (South Africa North):**
- Azure AD (RBAC: Admins, Managers, Agents, Viewers)
- Key Vault (secrets management)
- Application Insights + Log Analytics
- Storage Account (backups GRS)

---

## 📦 Structure du Projet

```
digitrans-cm-api/
├── api-gateway/              # Spring Cloud Gateway
├── erp-service/              # ERP + Auth JWT
├── crm-service/              # CRM
├── supply-chain-service/     # Supply Chain + RabbitMQ
├── bi-service/               # Business Intelligence
├── terraform/
│   ├── aws/                  # Infrastructure AWS (VPC, RDS, EKS, etc.)
│   └── azure/                # Infrastructure Azure (AD, Key Vault, Monitor)
├── .github/workflows/
│   └── ci-cd.yml             # Pipeline CI/CD complet
├── k8s/                      # Manifests Kubernetes
│   ├── 00-namespace.yaml
│   ├── redis-deployment.yaml
│   ├── rabbitmq-deployment.yaml
│   ├── *-service-deployment.yaml (5 services)
│   └── api-gateway-deployment.yaml (+ Ingress)
├── docker-compose.yml        # Dev local (sans MySQL)
├── deploy.sh                 # Script déploiement automatisé
├── .gitignore                # Exclusions (secrets, tfstate, etc.)
├── README.md                 # Documentation principale
├── INFRASTRUCTURE.md         # Doc infrastructure détaillée
├── SECRETS.md                # Guide secrets complet
└── SECRETS-QUICK-REFERENCE.md # Référence rapide secrets
```

---

## 🚀 Déploiement

### 1. Prérequis

```bash
# Outils
terraform >= 1.5
aws-cli >= 2.0
azure-cli >= 2.50
kubectl >= 1.28
docker >= 24.0
maven >= 3.8
java 17

# Comptes
- AWS Account (IAM user avec AdministratorAccess)
- Azure Subscription (App Registration)
- GitHub Account
```

### 2. Configuration Secrets

**GitHub Actions Secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
SLACK_WEBHOOK_URL
API_GATEWAY_URL
```

**Terraform Variables:**
```bash
# terraform/aws/terraform.tfvars
db_username = "admin"
db_password = "SECURE_PASSWORD"

# terraform/azure/terraform.tfvars
admin_group_members = ["admin@camtechsolutions.cm"]
```

### 3. Déploiement Infrastructure

**Option A: Script automatisé**
```bash
chmod +x deploy.sh
./deploy.sh prod apply
```

**Option B: Manuel**
```bash
# AWS
cd terraform/aws
terraform init
terraform workspace select prod
terraform apply -var="environment=prod"

# Azure
cd terraform/azure
az login
terraform init
terraform workspace select prod
terraform apply -var="environment=prod"

# Kubernetes
aws eks update-kubeconfig --name digitrans-cm-eks-prod --region af-south-1
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/rabbitmq-deployment.yaml
```

### 4. Déploiement Application (CI/CD)

**Automatique via GitHub Actions:**
```bash
git push origin main  # Déclenche pipeline → Production
```

**Manuel:**
```bash
# Build
mvn clean package -DskipTests

# Docker build & push
aws ecr get-login-password --region af-south-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
docker build -t $ECR_REGISTRY/digitrans-cm/erp-service:latest erp-service/
docker push $ECR_REGISTRY/digitrans-cm/erp-service:latest

# Deploy Kubernetes
kubectl apply -f k8s/erp-service-deployment.yaml
```

---

## 🔐 Sécurité

### Authentification & Autorisation
- JWT tokens (HMAC-SHA256, 256 bits)
- Roles: ROLE_ADMIN, ROLE_MANAGER, ROLE_AGENT, ROLE_VIEWER
- Azure AD integration (RBAC)
- Endpoints protégés (sauf /auth/login, /actuator/health)

### Chiffrement
- TLS 1.2+ (transit)
- AES-256 (repos: RDS, S3, ElastiCache)
- Certificats ACM (AWS Certificate Manager)

### Secrets Management
- Azure Key Vault (production)
- Kubernetes Secrets (runtime)
- AWS Secrets Manager (rotation DB passwords)
- Rotation: 90 jours (DB), 1 an (JWT)

### Network Security
- VPC isolé, sous-réseaux privés
- Security Groups restrictifs (principe moindre privilège)
- NAT Gateway (sortie internet contrôlée)
- VPC Flow Logs activés

### Audit & Conformité
- CloudTrail (tous appels API AWS)
- Azure Activity Log (changements AD/Key Vault)
- Loi camerounaise n°2010/012 (traçabilité)
- RGPD (données sur sol africain)

---

## 📊 Monitoring & Observabilité

### Métriques (CloudWatch + Azure Monitor)
- Disponibilité: 99.9% (SLA)
- Latence API: < 500ms (P95)
- Temps réponse DB: < 100ms (P95)
- CPU: < 70%, Mémoire: < 80%

### Logs
- CloudWatch Logs: `/aws/digitrans-cm/prod` (30j)
- Azure Log Analytics (multi-cloud)
- Application Insights (traces distribuées)

### Alertes
- SNS → Email: ops@camtechsolutions.cm
- SMS: +237 699 000 001
- Slack webhook

### Dashboards
- CloudWatch: RDS, ALB, ElastiCache, EKS
- Azure Monitor: Temps réponse, erreurs, dépendances
- Grafana (optionnel)

---

## 💰 Coûts & Optimisation

### Budget Mensuel (Production)

| Service | Coût |
|---------|------|
| EKS (3 nodes t3.medium) | ~220 USD |
| RDS (3x db.t3.medium Multi-AZ) | ~450 USD |
| ElastiCache (2 nodes) | ~180 USD |
| ALB + S3 + CloudWatch | ~105 USD |
| Azure (Key Vault + Monitor) | ~100 USD |
| **Total** | **~1055 USD/mois** |

### Stratégies d'optimisation
- Auto-scaling (scale down 22h-6h)
- Reserved Instances (économie 40%)
- S3 Lifecycle (Glacier après 90j)
- Logs rétention 7j (dev), 30j (prod)
- Cost Explorer alertes > 500 USD/mois

---

## 🧪 Tests

### Tests Unitaires
```bash
mvn test
```

### Tests d'intégration
```bash
mvn verify
```

### Tests de charge (k6)
```bash
k6 run --vus 100 --duration 5m tests/load-test.js
```

### Tests de sécurité (Trivy)
```bash
trivy fs .
trivy image $ECR_REGISTRY/digitrans-cm/erp-service:latest
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Documentation principale |
| [INFRASTRUCTURE.md](INFRASTRUCTURE.md) | Architecture détaillée, procédures ops |
| [SECRETS.md](SECRETS.md) | Guide complet secrets & rotation |
| [SECRETS-QUICK-REFERENCE.md](SECRETS-QUICK-REFERENCE.md) | Référence rapide |

### API Documentation (Swagger)
- ERP: http://localhost:8081/swagger-ui.html
- CRM: http://localhost:8082/swagger-ui.html
- Supply: http://localhost:8083/swagger-ui.html
- BI: http://localhost:8084/swagger-ui.html

---

## 🎯 Conformité Examen (I.3)

| Critère | Statut | Preuve |
|---------|--------|--------|
| **I.3.1** Architecture cloud hybride | ✅ | terraform/aws/, terraform/azure/ |
| **I.3.1** Régions africaines | ✅ | af-south-1, southafricanorth |
| **I.3.1** Souveraineté données | ✅ | RDS Cape Town, Azure SA North |
| **I.3.2** Environnements séparés | ✅ | Terraform workspaces (dev/test/prod) |
| **I.3.2** Variables isolées | ✅ | terraform.tfvars par env |
| **I.3.3** Pipeline CI/CD | ✅ | .github/workflows/ci-cd.yml |
| **I.3.3** Build automatisé | ✅ | Maven + Docker |
| **I.3.3** Tests automatisés | ✅ | Unit tests + Trivy + k6 |
| **I.3.3** Déploiement auto | ✅ | Kubernetes rolling update |
| **I.3.4** Conteneurisation | ✅ | Dockerfiles (5 services) |
| **I.3.4** Orchestration K8s | ✅ | EKS + manifests k8s/ |
| **I.3.4** Auto-scaling | ✅ | HPA (CPU 70%, Memory 80%) |
| **I.3.5** Monitoring | ✅ | CloudWatch + Azure Monitor |
| **I.3.5** Alertes | ✅ | SNS + Email + SMS |
| **I.3.5** Optimisation coûts | ✅ | Auto-scaling, RI, Lifecycle |

---

## 🔧 Maintenance

### Backup
```bash
# RDS (automatique, rétention 7j)
aws rds create-db-snapshot --db-instance-identifier digitrans-cm-erp-prod

# Kubernetes (Velero)
velero backup create digitrans-cm-backup-$(date +%Y%m%d)
```

### Restore
```bash
# RDS
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier digitrans-cm-erp-restored \
  --db-snapshot-identifier erp-manual-20260115

# Kubernetes
velero restore create --from-backup digitrans-cm-backup-20260115
```

### Rollback
```bash
kubectl rollout undo deployment/erp-service -n digitrans-cm
```

### Scaling manuel
```bash
kubectl scale deployment/erp-service --replicas=6 -n digitrans-cm
```

---

## 👥 Équipe & Contacts

| Rôle | Contact | Disponibilité |
|------|---------|---------------|
| DevOps Lead | devops@camtechsolutions.cm | 24/7 |
| Ops Team | ops@camtechsolutions.cm | 24/7 |
| Security Team | security@camtechsolutions.cm | 24/7 |
| AWS Support | Enterprise Support | 24/7 |
| Azure Support | Professional Direct | 24/7 |

---

## 📝 Changelog

### v1.0.0 (2026-01-15)
- ✅ Architecture microservices Spring Boot 3.2
- ✅ Infrastructure Terraform (AWS + Azure)
- ✅ Pipeline CI/CD GitHub Actions
- ✅ Kubernetes EKS avec auto-scaling
- ✅ Monitoring CloudWatch + Azure Monitor
- ✅ Documentation complète

---

## 📄 Licence

Propriété de CAMTECH SOLUTIONS S.A. - Tous droits réservés.  
Client: AGROCAM S.A.  
Projet: DIGITRANS-CM

---

**Repository:** https://github.com/carmelle2/digitrans-cm  
**Date:** Janvier 2026  
**Version:** 1.0.0
