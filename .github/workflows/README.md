# GitHub Actions Workflows

## Workflows Disponibles

### 1. CI Pipeline (ci.yml) - ACTIF ✅

**Déclenchement:** Push sur main/develop, Pull Request

**Jobs:**
- ✅ Build & Test (Maven) - Tous les 5 microservices
- ✅ Security Scan (Trivy) - Vulnérabilités
- ✅ Build Docker Images - Sans push (validation locale)
- ✅ Validate Kubernetes - Dry-run des manifests
- ✅ Validate Terraform - Format & validate

**Avantages:**
- Fonctionne sans credentials AWS/Azure
- Validation complète du code
- Rapide (5-10 minutes)

### 2. CI/CD Pipeline (ci-cd.yml.disabled) - DÉSACTIVÉ ⚠️

**Pourquoi désactivé:**
- Nécessite credentials AWS (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- Nécessite cluster EKS déjà déployé
- Nécessite ECR registry configuré

**Pour activer:**
1. Configurer les secrets GitHub:
   ```
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   AWS_ACCOUNT_ID
   SLACK_WEBHOOK_URL
   API_GATEWAY_URL
   ```

2. Déployer l'infrastructure Terraform:
   ```bash
   cd terraform/aws
   terraform apply
   ```

3. Renommer le fichier:
   ```bash
   mv .github/workflows/ci-cd.yml.disabled .github/workflows/ci-cd.yml
   ```

## Configuration des Secrets

### GitHub Repository Secrets

Aller dans: `Settings > Secrets and variables > Actions > New repository secret`

**Obligatoires pour CI/CD complet:**
```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_ACCOUNT_ID=123456789012
```

**Optionnels:**
```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00/B00/XXXX
API_GATEWAY_URL=https://api.digitrans-cm.agrocam.cm
```

## Workflow Actuel (ci.yml)

### Étapes

1. **Build and Test** (5 services en parallèle)
   - Checkout code
   - Setup JDK 17
   - Maven build
   - Maven test
   - Upload artifacts

2. **Security Scan**
   - Trivy filesystem scan
   - Détection vulnérabilités CRITICAL/HIGH

3. **Build Docker**
   - Download artifacts
   - Build images Docker
   - Trivy image scan

4. **Validate Kubernetes**
   - kubectl dry-run sur tous les manifests

5. **Validate Terraform**
   - terraform fmt check
   - terraform init (sans backend)
   - terraform validate (AWS + Azure)

6. **Summary**
   - Résumé dans GitHub Actions UI

## Logs et Debugging

### Voir les logs
```
GitHub > Actions > Sélectionner un workflow run > Cliquer sur un job
```

### Erreurs communes

**Maven build failed:**
- Vérifier pom.xml
- Vérifier dépendances

**Docker build failed:**
- Vérifier Dockerfile
- Vérifier que les JARs sont présents

**Kubernetes validation failed:**
- Vérifier syntaxe YAML
- Vérifier que les images existent

**Terraform validation failed:**
- Vérifier syntaxe HCL
- Vérifier providers

## Prochaines Étapes

1. ✅ Workflow CI fonctionne (validation code)
2. ⏳ Configurer secrets AWS
3. ⏳ Déployer infrastructure Terraform
4. ⏳ Activer workflow CI/CD complet
5. ⏳ Déploiement automatique sur EKS

## Support

En cas de problème:
- Vérifier les logs dans GitHub Actions
- Consulter [QUICKSTART.md](../../QUICKSTART.md)
- Consulter [INFRASTRUCTURE.md](../../INFRASTRUCTURE.md)
