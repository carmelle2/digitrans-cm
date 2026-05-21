# DIGITRANS-CM - Guide Rapide des Secrets

## 🔑 Secrets Essentiels à Configurer

### 1. GitHub Actions (Obligatoire pour CI/CD)

```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_ACCOUNT_ID=123456789012
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00/B00/XXXX
API_GATEWAY_URL=https://api.digitrans-cm.agrocam.cm
```

### 2. Terraform Variables (terraform.tfvars)

**AWS:**
```hcl
db_username = "admin"
db_password = "ChangeMeSecurePassword123!@#"
```

**Azure:**
```hcl
admin_group_members = ["admin@camtechsolutions.cm"]
```

### 3. Kubernetes Secrets

```bash
kubectl create secret generic digitrans-cm-secrets \
  --from-literal=JWT_SECRET='agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits' \
  --from-literal=DB_USER='admin' \
  --from-literal=DB_PASS='ChangeMeSecurePassword123!@#' \
  --from-literal=RABBITMQ_PASS='SecureRabbitMQPassword456$%^' \
  -n digitrans-cm
```

### 4. Local Development (.env)

```env
JWT_SECRET=agrocam-digitrans-secret-key-2024-very-long-secret-min-256-bits
DB_USER=root
DB_PASS=
RABBITMQ_USER=guest
RABBITMQ_PASS=guest
```

---

## 📋 Checklist Déploiement

- [ ] Créer compte AWS IAM avec accès programmatique
- [ ] Configurer AWS CLI: `aws configure`
- [ ] Créer App Registration Azure AD
- [ ] Configurer Azure CLI: `az login`
- [ ] Ajouter secrets dans GitHub Actions
- [ ] Créer fichiers terraform.tfvars (AWS + Azure)
- [ ] Générer JWT secret fort (256 bits min)
- [ ] Créer passwords DB sécurisés
- [ ] Configurer Slack webhook
- [ ] Demander certificat SSL (ACM)

---

## 🔐 Générer Secrets Sécurisés

```bash
# JWT Secret (256 bits)
openssl rand -base64 64

# DB Password
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25

# RabbitMQ Password
openssl rand -base64 24
```

---

## ⚠️ IMPORTANT

- **NE JAMAIS** commiter secrets dans Git
- Utiliser `.gitignore` pour exclure fichiers sensibles
- Stocker dans Azure Key Vault (production)
- Rotation tous les 90 jours (DB passwords)
- Backup secrets dans coffre-fort sécurisé

---

Voir **SECRETS.md** pour documentation complète.
