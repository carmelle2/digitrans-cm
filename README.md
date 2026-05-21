# digitrans-cm-api — AGROCAM S.A.

Plateforme de digitalisation des opérations d'AGROCAM S.A. — architecture microservices Spring Boot 3.2.

## Architecture

```
                        ┌─────────────────────────────────────────────────────┐
                        │              CLIENTS (Web / Mobile)                  │
                        └──────────────────────┬──────────────────────────────┘
                                               │ HTTPS
                        ┌──────────────────────▼──────────────────────────────┐
                        │           API GATEWAY  :8080                         │
                        │     (Spring Cloud Gateway + JWT validation)          │
                        └──┬──────────┬──────────┬──────────┬─────────────────┘
                           │          │          │          │
              ┌────────────▼──┐  ┌────▼──────┐  ┌▼──────────────┐  ┌──────────▼────┐
              │ ERP  :8081    │  │ CRM :8082 │  │ SUPPLY :8083  │  │  BI   :8084   │
              │ Employees     │  │ Customers │  │ Products      │  │ Dashboard     │
              │ Suppliers     │  │ Orders    │  │ Shipments     │  │ Order Stats   │
              │ Accounting    │  │Restaurants│  │ Checkpoints   │  │ Revenue       │
              └──────┬────────┘  └─────┬─────┘  └──────┬────────┘  └──────┬────────┘
                     │                 │                │                  │
              ┌──────▼─────────────────▼────────────────▼──────────────────▼────────┐
              │                    INFRASTRUCTURE                                     │
              │   MySQL (WampServer :3306)  │  Redis :6379  │  RabbitMQ :5672        │
              │   erp_db / crm_db           │  Cache TTL    │  shipment.exchange      │
              │   supply_db / bi_db         │  60s / 300s   │  (pub/sub events)       │
              └─────────────────────────────────────────────────────────────────────┘
```

## Prérequis

- Java 17+
- Maven 3.8+
- WampServer (MySQL 8.0 sur port 3306)
- Redis 7+ (ou Docker)
- RabbitMQ 3.12+ (ou Docker)

---

## 1. Configuration WampServer (MySQL)

Ouvrir phpMyAdmin (`http://localhost/phpmyadmin`) ou MySQL CLI et créer les 4 bases :

```sql
CREATE DATABASE IF NOT EXISTS erp_db    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS crm_db    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS supply_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS bi_db     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

> Par défaut WampServer : user=`root`, password=`(vide)`, port=`3306`

---

## 2. Lancer en local (sans Docker)

### Build complet
```bash
cd digitrans-cm-api
mvn clean package -DskipTests
```

### Démarrer chaque service (dans des terminaux séparés)
```bash
java -jar erp-service/target/erp-service-1.0.0-SNAPSHOT.jar
java -jar crm-service/target/crm-service-1.0.0-SNAPSHOT.jar
java -jar supply-chain-service/target/supply-chain-service-1.0.0-SNAPSHOT.jar
java -jar bi-service/target/bi-service-1.0.0-SNAPSHOT.jar
java -jar api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar
```

Flyway exécutera automatiquement les migrations V1 (schema) et V2 (seed data) au démarrage.

---

## 3. Lancer avec Docker (MySQL sur WampServer)

> MySQL reste sur WampServer — Docker ne contient que Redis, RabbitMQ et les services Spring Boot.

### Build des images
```bash
cd digitrans-cm-api
mvn clean package -DskipTests
docker-compose build
```

### Démarrer
```bash
docker-compose up -d
```

### Vérifier
```bash
docker-compose ps
docker-compose logs -f erp-service
```

> Les services Docker se connectent à MySQL via `host.docker.internal:3306`.
> Sur Linux, `extra_hosts: host.docker.internal:host-gateway` est requis (déjà configuré).

---

## 4. Authentification JWT

### Obtenir un token
```bash
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

Comptes de démonstration :
| Username | Password | Role         |
|----------|----------|--------------|
| admin    | password | ROLE_ADMIN   |
| manager  | password | ROLE_MANAGER |
| agent    | password | ROLE_AGENT   |
| viewer   | password | ROLE_VIEWER  |

### Utiliser le token
```bash
curl -H "Authorization: Bearer <token>" http://localhost:8081/api/erp/employees
```

---

## 5. Endpoints principaux

| Service | Port | Endpoints |
|---------|------|-----------|
| ERP     | 8081 | `/api/erp/employees`, `/api/erp/suppliers`, `/api/erp/accounting` |
| CRM     | 8082 | `/api/crm/customers`, `/api/crm/orders`, `/api/crm/restaurants` |
| Supply  | 8083 | `/api/supply/products`, `/api/supply/shipments` |
| BI      | 8084 | `/api/bi/dashboard`, `/api/bi/orders/stats`, `/api/bi/supply/stats`, `/api/bi/revenue/monthly` |
| Gateway | 8080 | Proxy vers tous les services |

---

## 6. Swagger UI

| Service | URL |
|---------|-----|
| ERP     | http://localhost:8081/swagger-ui.html |
| CRM     | http://localhost:8082/swagger-ui.html |
| Supply  | http://localhost:8083/swagger-ui.html |
| BI      | http://localhost:8084/swagger-ui.html |

---

## 7. RabbitMQ Management

http://localhost:15672 — user: `guest` / pass: `guest`

Exchange: `shipment.exchange`
Queues: `erp.shipment.queue`, `bi.shipment.queue`

---

## 8. Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `JWT_SECRET` | `agrocam-digitrans-secret-key-2024-very-long-secret` | Clé HMAC-SHA256 |
| `REDIS_HOST` | `localhost` | Hôte Redis |
| `RABBITMQ_HOST` | `localhost` | Hôte RabbitMQ |
| `DB_USER` | `root` | Utilisateur MySQL |
| `DB_PASS` | `` | Mot de passe MySQL |

---

## 9. Infrastructure Cloud (AWS + Azure)

### Architecture Hybride

Le projet DIGITRANS-CM est déployé sur une infrastructure cloud hybride:

- **AWS (Cape Town - af-south-1)**: Services applicatifs, bases de données, cache, orchestration Kubernetes
- **Azure (South Africa North)**: Gestion des identités (Azure AD), supervision centralisée, secrets management

### Déploiement Infrastructure

#### Prérequis
```bash
terraform >= 1.5
aws-cli >= 2.0
azure-cli >= 2.50
kubectl >= 1.28
```

#### Déploiement automatisé
```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Déployer l'infrastructure complète (AWS + Azure + Kubernetes)
./deploy.sh prod apply

# Planifier les changements sans appliquer
./deploy.sh prod plan

# Détruire l'infrastructure
./deploy.sh prod destroy
```

#### Déploiement manuel

**1. Infrastructure AWS**
```bash
cd terraform/aws
terraform init
terraform workspace select prod
terraform apply -var="environment=prod"
```

**2. Infrastructure Azure**
```bash
cd terraform/azure
az login
terraform init
terraform workspace select prod
terraform apply -var="environment=prod"
```

**3. Configuration Kubernetes (EKS)**
```bash
# Mettre à jour kubeconfig
aws eks update-kubeconfig --name digitrans-cm-eks-prod --region af-south-1

# Déployer les manifests
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/rabbitmq-deployment.yaml

# Attendre que les services soient prêts
kubectl wait --for=condition=ready pod -l app=redis -n digitrans-cm --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n digitrans-cm --timeout=300s
```

### Pipeline CI/CD (GitHub Actions)

Le pipeline automatise:
1. Build & Test (Maven)
2. Security Scan (Trivy)
3. Docker Build & Push (ECR)
4. Deploy to EKS (Kubernetes)
5. Performance Tests (k6)
6. Notifications (Slack)

**Secrets GitHub requis:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
SLACK_WEBHOOK_URL
API_GATEWAY_URL
```

**Déclenchement:**
- Push sur `main` → Déploiement production
- Push sur `develop` → Déploiement test
- Pull Request → Build + tests uniquement

### Monitoring

**CloudWatch (AWS)**
- Logs: `/aws/digitrans-cm/prod`
- Métriques: RDS, ALB, ElastiCache, EKS
- Alarmes: SNS → ops@camtechsolutions.cm

**Azure Monitor**
- Application Insights: Temps réponse, taux erreur
- Log Analytics: Logs centralisés multi-cloud
- Alertes: Email + SMS

### Coûts estimés (production)

| Service | Coût mensuel |
|---------|-------------|
| EKS (3 nodes t3.medium) | ~220 USD |
| RDS (3x db.t3.medium Multi-AZ) | ~450 USD |
| ElastiCache (2 nodes) | ~180 USD |
| ALB + S3 + CloudWatch | ~105 USD |
| Azure (Key Vault + Monitor) | ~100 USD |
| **Total** | **~1055 USD/mois** |

### Documentation complète

Consultez [INFRASTRUCTURE.md](INFRASTRUCTURE.md) pour:
- Architecture détaillée
- Procédures opérationnelles
- Stratégies de backup/restore
- Optimisation des coûts
- Sécurité & conformité
