# DIGITRANS-CM - Secrets et Configuration

## ⚠️ IMPORTANT: Ne jamais commiter ce fichier dans Git!

Ce document liste tous les secrets et clés nécessaires pour le projet DIGITRANS-CM.

---

## 1. GitHub Actions Secrets

Configurer dans: `Settings > Secrets and variables > Actions > New repository secret`

### AWS Credentials
```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_ACCOUNT_ID=123456789012
AWS_REGION=af-south-1
```

**Comment obtenir:**
1. Connexion AWS Console
2. IAM > Users > Create User
3. Attach policies: `AdministratorAccess` (ou policies spécifiques)
4. Security credentials > Create access key

### Azure Credentials
```
AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789012
AZURE_CLIENT_SECRET=your-azure-client-secret
AZURE_TENANT_ID=87654321-4321-4321-4321-210987654321
AZURE_SUBSCRIPTION_ID=abcdef12-3456-7890-abcd-ef1234567890
```

**Comment obtenir:**
1. Connexion Azure Portal
2. Azure Active Directory > App registrations > New registration
3. Certificates & secrets > New client secret
4. Copy: Application (client) ID, Directory (tenant) ID, Subscription ID

### Notifications
```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

**Comment obtenir:**
1. Slack Workspace > Apps > Incoming Webhooks
2. Add to Slack > Choose channel
3. Copy Webhook URL

### Application URLs
```
API_GATEWAY_URL=https://api.digitrans-cm.agrocam.cm
```

---

## 2. Terraform Variables (terraform.tfvars)

### AWS (terraform/aws/terraform.tfvars)
```hcl
# Environment
environment = "prod"
aws_region  = "af-south-1"

# Network
vpc_cidr = "10.0.0.0/16"

# Database Credentials
db_username = "admin"
db_password = "ChangeMeSecurePassword123!@#"

# Tags
cost_center  = "DIGITRANS-CM"
project_code = "AGROCAM-2026"
```

### Azure (terraform/azure/terraform.tfvars)
```hcl
# Environment
environment  = "prod"
azure_region = "southafricanorth"

# Admin Users (Azure AD)
admin_group_members = [
  "admin@camtechsolutions.cm",
  "devops@camtechsolutions.cm"
]
```

---

## 3. Kubernetes Secrets

### Créer les secrets manuellement
```bash
# Namespace
kubectl create namespace digitrans-cm

# Secrets principaux
kubectl create secret generic digitrans-cm-secrets \
  --from-literal=JWT_SECRET='agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits' \
  --from-literal=DB_USER='admin' \
  --from-literal=DB_PASS='ChangeMeSecurePassword123!@#' \
  --from-literal=RABBITMQ_PASS='SecureRabbitMQPassword456$%^' \
  -n digitrans-cm

# Secrets RDS endpoints (après déploiement Terraform)
kubectl create secret generic digitrans-cm-rds \
  --from-literal=ERP_ENDPOINT='digitrans-cm-erp-prod.xxxxxxxxxx.af-south-1.rds.amazonaws.com:3306' \
  --from-literal=CRM_ENDPOINT='digitrans-cm-crm-prod.xxxxxxxxxx.af-south-1.rds.amazonaws.com:3306' \
  --from-literal=SUPPLY_ENDPOINT='digitrans-cm-supply-prod.xxxxxxxxxx.af-south-1.rds.amazonaws.com:3306' \
  -n digitrans-cm

# Secrets Azure (Application Insights)
kubectl create secret generic digitrans-cm-azure \
  --from-literal=APPINSIGHTS_INSTRUMENTATION_KEY='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' \
  --from-literal=APPINSIGHTS_CONNECTION_STRING='InstrumentationKey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx;...' \
  -n digitrans-cm
```

---

## 4. Azure Key Vault Secrets

Stocker dans Azure Key Vault: `digitrans-cm-kv-prod`

```bash
# Login Azure
az login

# Créer les secrets
az keyvault secret set --vault-name digitrans-cm-kv-prod --name db-username --value "admin"
az keyvault secret set --vault-name digitrans-cm-kv-prod --name db-password --value "ChangeMeSecurePassword123!@#"
az keyvault secret set --vault-name digitrans-cm-kv-prod --name jwt-secret --value "agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits"
az keyvault secret set --vault-name digitrans-cm-kv-prod --name rabbitmq-password --value "SecureRabbitMQPassword456$%^"
az keyvault secret set --vault-name digitrans-cm-kv-prod --name slack-webhook --value "https://hooks.slack.com/services/..."
```

---

## 5. Application Properties (Local Development)

### erp-service/src/main/resources/application-local.properties
```properties
# MySQL Local (WampServer)
spring.datasource.url=jdbc:mysql://localhost:3306/erp_db?useSSL=false&serverTimezone=Africa/Douala
spring.datasource.username=root
spring.datasource.password=

# Redis Local
spring.data.redis.host=localhost
spring.data.redis.port=6379

# RabbitMQ Local
spring.rabbitmq.host=localhost
spring.rabbitmq.port=5672
spring.rabbitmq.username=guest
spring.rabbitmq.password=guest

# JWT
jwt.secret=agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits
```

**Répéter pour:** crm-service, supply-chain-service, bi-service

---

## 6. Docker Compose Secrets (.env)

Créer fichier `.env` à la racine:
```env
# Database
DB_USER=root
DB_PASS=
MYSQL_ROOT_PASSWORD=

# JWT
JWT_SECRET=agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits

# RabbitMQ
RABBITMQ_USER=guest
RABBITMQ_PASS=guest

# Redis (pas de password par défaut)
REDIS_HOST=redis
REDIS_PORT=6379
```

---

## 7. SSL/TLS Certificates

### Générer certificat auto-signé (dev/test)
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=CM/ST=Littoral/L=Douala/O=CAMTECH Solutions/OU=IT/CN=digitrans-cm.agrocam.cm"
```

### Production (AWS Certificate Manager)
```bash
# Demander certificat via ACM
aws acm request-certificate \
  --domain-name digitrans-cm.agrocam.cm \
  --subject-alternative-names api.digitrans-cm.agrocam.cm \
  --validation-method DNS \
  --region af-south-1

# Récupérer ARN du certificat
aws acm list-certificates --region af-south-1
```

**ARN à utiliser dans:** `k8s/api-gateway-deployment.yaml` (annotation Ingress)

---

## 8. Rotation des Secrets (Recommandations)

### Fréquence de rotation

| Secret | Fréquence | Méthode |
|--------|-----------|---------|
| DB Password | 90 jours | AWS Secrets Manager auto-rotation |
| JWT Secret | 1 an | Manuel (redéploiement) |
| API Keys | 6 mois | Manuel |
| SSL Certificates | Avant expiration | ACM auto-renewal |
| RabbitMQ Password | 90 jours | Manuel |

### Procédure rotation DB Password
```bash
# 1. Générer nouveau password
NEW_PASS=$(openssl rand -base64 32)

# 2. Mettre à jour RDS
aws rds modify-db-instance \
  --db-instance-identifier digitrans-cm-erp-prod \
  --master-user-password "$NEW_PASS" \
  --apply-immediately

# 3. Mettre à jour Kubernetes secret
kubectl create secret generic digitrans-cm-secrets \
  --from-literal=DB_PASS="$NEW_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Redémarrer pods
kubectl rollout restart deployment -n digitrans-cm
```

---

## 9. Backup des Secrets

### Exporter secrets Kubernetes (chiffré)
```bash
# Installer kubeseal (Sealed Secrets)
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Sceller les secrets
kubectl get secret digitrans-cm-secrets -n digitrans-cm -o yaml | \
  kubeseal -o yaml > sealed-secrets.yaml

# Commiter sealed-secrets.yaml (sécurisé)
git add sealed-secrets.yaml
git commit -m "Add sealed secrets"
```

### Backup Azure Key Vault
```bash
# Exporter tous les secrets
az keyvault secret list --vault-name digitrans-cm-kv-prod --query "[].id" -o tsv | \
  while read secret; do
    name=$(basename $secret)
    az keyvault secret show --id $secret --query "value" -o tsv > "backup-$name.txt"
  done

# Stocker backup-*.txt dans coffre-fort sécurisé (pas Git!)
```

---

## 10. Checklist Sécurité

- [ ] Tous les secrets sont dans `.gitignore`
- [ ] GitHub Actions secrets configurés
- [ ] Terraform backend S3/Azure Storage chiffré
- [ ] RDS encryption at rest activé
- [ ] ElastiCache encryption activé
- [ ] S3 bucket private (Block Public Access)
- [ ] Azure Key Vault soft-delete activé
- [ ] SSL/TLS certificats valides
- [ ] Rotation automatique DB passwords (AWS Secrets Manager)
- [ ] Monitoring alertes configurées
- [ ] Backup secrets externalisé (coffre-fort)
- [ ] IAM policies principe du moindre privilège
- [ ] Security Groups restrictifs (ports minimaux)
- [ ] VPC flow logs activés
- [ ] CloudTrail logging activé
- [ ] Azure Activity Log activé

---

## 11. Contacts Urgence

| Rôle | Contact | Disponibilité |
|------|---------|---------------|
| DevOps Lead | devops@camtechsolutions.cm | 24/7 |
| Security Team | security@camtechsolutions.cm | 24/7 |
| AWS Support | Enterprise Support | 24/7 |
| Azure Support | Professional Direct | 24/7 |

---

## 12. Génération Secrets Sécurisés

### JWT Secret (256 bits minimum)
```bash
openssl rand -base64 64
# Résultat: agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits-XXXXXXXXXXXXXXXX
```

### Database Password (fort)
```bash
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
# Résultat: ChangeMeSecurePassword123
```

### RabbitMQ Password
```bash
openssl rand -base64 24
# Résultat: SecureRabbitMQPassword456
```

### API Key
```bash
uuidgen | tr '[:upper:]' '[:lower:]'
# Résultat: 12345678-1234-1234-1234-123456789012
```

---

**RAPPEL CRITIQUE:** 
- Ne JAMAIS commiter ce fichier dans Git
- Stocker dans gestionnaire de mots de passe d'équipe (1Password, LastPass, etc.)
- Partager via canal sécurisé (pas email/Slack)
- Rotation régulière selon tableau ci-dessus
