# 🚀 DIGITRANS-CM - Guide de Démarrage Rapide

## ⚡ Démarrage en 5 minutes (Local)

### 1. Prérequis
```bash
✅ Java 17
✅ Maven 3.8+
✅ WampServer (MySQL 8.0)
✅ Docker Desktop (optionnel)
```

### 2. Créer les bases de données MySQL
```sql
-- Ouvrir phpMyAdmin (http://localhost/phpmyadmin)
CREATE DATABASE erp_db CHARACTER SET utf8mb4;
CREATE DATABASE crm_db CHARACTER SET utf8mb4;
CREATE DATABASE supply_db CHARACTER SET utf8mb4;
CREATE DATABASE bi_db CHARACTER SET utf8mb4;
```

### 3. Lancer l'application
```bash
# Cloner le projet
git clone https://github.com/carmelle2/digitrans-cm.git
cd digitrans-cm

# Build
mvn clean package -DskipTests

# Lancer avec Docker Compose (Redis + RabbitMQ + Services)
docker-compose up -d

# OU lancer manuellement chaque service
java -jar erp-service/target/erp-service-1.0.0-SNAPSHOT.jar
java -jar crm-service/target/crm-service-1.0.0-SNAPSHOT.jar
java -jar supply-chain-service/target/supply-chain-service-1.0.0-SNAPSHOT.jar
java -jar bi-service/target/bi-service-1.0.0-SNAPSHOT.jar
java -jar api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar
```

### 4. Tester l'API
```bash
# Obtenir un token JWT
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Utiliser le token
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8081/api/erp/employees
```

### 5. Accéder aux interfaces
- **API Gateway**: http://localhost:8080
- **Swagger ERP**: http://localhost:8081/swagger-ui.html
- **Swagger CRM**: http://localhost:8082/swagger-ui.html
- **Swagger Supply**: http://localhost:8083/swagger-ui.html
- **Swagger BI**: http://localhost:8084/swagger-ui.html
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

---

## ☁️ Déploiement Cloud (Production)

### 1. Configurer les credentials

**AWS:**
```bash
aws configure
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/...
# Default region: af-south-1
```

**Azure:**
```bash
az login
```

### 2. Configurer les secrets

**GitHub Actions:**
```
Settings > Secrets > Actions > New repository secret

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
SLACK_WEBHOOK_URL
```

**Terraform:**
```bash
# Créer terraform/aws/terraform.tfvars
cat > terraform/aws/terraform.tfvars <<EOF
environment = "prod"
db_username = "admin"
db_password = "SECURE_PASSWORD_HERE"
EOF

# Créer terraform/azure/terraform.tfvars
cat > terraform/azure/terraform.tfvars <<EOF
environment = "prod"
admin_group_members = ["admin@camtechsolutions.cm"]
EOF
```

### 3. Déployer l'infrastructure

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
terraform apply -var="environment=prod"

# Azure
cd terraform/azure
terraform init
terraform apply -var="environment=prod"

# Kubernetes
aws eks update-kubeconfig --name digitrans-cm-eks-prod --region af-south-1
kubectl apply -f k8s/
```

### 4. Déployer l'application
```bash
# Push vers GitHub → Pipeline CI/CD automatique
git push origin main

# OU build et push manuel
mvn clean package -DskipTests
docker build -t $ECR_REGISTRY/digitrans-cm/erp-service:latest erp-service/
docker push $ECR_REGISTRY/digitrans-cm/erp-service:latest
kubectl apply -f k8s/erp-service-deployment.yaml
```

---

## 🔑 Comptes de test

| Username | Password | Role |
|----------|----------|------|
| admin | password | ROLE_ADMIN |
| manager | password | ROLE_MANAGER |
| agent | password | ROLE_AGENT |
| viewer | password | ROLE_VIEWER |

---

## 📊 Endpoints principaux

### ERP (8081)
```
GET  /api/erp/employees
POST /api/erp/employees
GET  /api/erp/suppliers
GET  /api/erp/accounting
POST /auth/login
```

### CRM (8082)
```
GET  /api/crm/customers
POST /api/crm/customers
GET  /api/crm/orders
PUT  /api/crm/orders/{id}/status
GET  /api/crm/restaurants
```

### Supply Chain (8083)
```
GET  /api/supply/products
GET  /api/supply/shipments
PUT  /api/supply/shipments/{id}/status
POST /api/supply/shipments/{id}/checkpoint
```

### BI (8084)
```
GET /api/bi/dashboard
GET /api/bi/orders/stats
GET /api/bi/supply/stats
GET /api/bi/revenue/monthly
```

---

## 🐛 Dépannage

### Erreur: "Connection refused" MySQL
```bash
# Vérifier que WampServer est démarré
# Vérifier que les bases sont créées
mysql -u root -e "SHOW DATABASES;"
```

### Erreur: "Port already in use"
```bash
# Trouver le processus
netstat -ano | findstr :8081
# Tuer le processus
taskkill /PID <PID> /F
```

### Erreur: Flyway migration failed
```bash
# Supprimer et recréer la base
mysql -u root -e "DROP DATABASE erp_db; CREATE DATABASE erp_db;"
```

### Erreur: Redis connection refused
```bash
# Lancer Redis avec Docker
docker run -d -p 6379:6379 redis:7-alpine
```

### Erreur: RabbitMQ connection refused
```bash
# Lancer RabbitMQ avec Docker
docker run -d -p 5672:5672 -p 15672:15672 rabbitmq:3.12-management-alpine
```

---

## 📚 Documentation complète

- **[README.md](README.md)** - Documentation principale
- **[PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)** - Vue d'ensemble complète
- **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)** - Architecture cloud détaillée
- **[SECRETS.md](SECRETS.md)** - Guide secrets & sécurité
- **[SECRETS-QUICK-REFERENCE.md](SECRETS-QUICK-REFERENCE.md)** - Référence rapide

---

## 💡 Commandes utiles

```bash
# Logs en temps réel
kubectl logs -f deployment/erp-service -n digitrans-cm

# Status des pods
kubectl get pods -n digitrans-cm -w

# Redémarrer un service
kubectl rollout restart deployment/erp-service -n digitrans-cm

# Rollback
kubectl rollout undo deployment/erp-service -n digitrans-cm

# Scale manuel
kubectl scale deployment/erp-service --replicas=5 -n digitrans-cm

# Accéder à un pod
kubectl exec -it <pod-name> -n digitrans-cm -- /bin/sh

# Port-forward pour debug
kubectl port-forward svc/erp-service 8081:8081 -n digitrans-cm
```

---

## 🎯 Prochaines étapes

1. ✅ Configurer GitHub Actions secrets
2. ✅ Déployer infrastructure Terraform
3. ✅ Pousser code → Déclenchement pipeline
4. ✅ Vérifier déploiement Kubernetes
5. ✅ Tester endpoints API
6. ✅ Configurer monitoring/alertes
7. ✅ Documenter procédures ops

---

**Support:** ops@camtechsolutions.cm  
**Repository:** https://github.com/carmelle2/digitrans-cm  
**Documentation:** Voir fichiers *.md à la racine
