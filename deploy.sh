#!/bin/bash
# DIGITRANS-CM Infrastructure Deployment Script
# Usage: ./deploy.sh [environment] [action]
# Example: ./deploy.sh prod apply

set -e

ENVIRONMENT=${1:-prod}
ACTION=${2:-plan}
AWS_REGION="af-south-1"
AZURE_REGION="southafricanorth"

echo "========================================="
echo "DIGITRANS-CM Infrastructure Deployment"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    command -v terraform >/dev/null 2>&1 || { print_error "terraform is required but not installed. Aborting."; exit 1; }
    command -v aws >/dev/null 2>&1 || { print_error "aws-cli is required but not installed. Aborting."; exit 1; }
    command -v az >/dev/null 2>&1 || { print_error "azure-cli is required but not installed. Aborting."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is required but not installed. Aborting."; exit 1; }
    
    print_info "All prerequisites met!"
}

# Deploy AWS infrastructure
deploy_aws() {
    print_info "Deploying AWS infrastructure..."
    
    cd terraform/aws
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    
    # Plan or Apply
    if [ "$ACTION" == "plan" ]; then
        terraform plan -var="environment=$ENVIRONMENT" -out=tfplan
    elif [ "$ACTION" == "apply" ]; then
        terraform apply -var="environment=$ENVIRONMENT" -auto-approve
        
        # Export outputs
        terraform output -json > ../../outputs/aws-$ENVIRONMENT.json
        print_info "AWS outputs saved to outputs/aws-$ENVIRONMENT.json"
    elif [ "$ACTION" == "destroy" ]; then
        print_warn "Destroying AWS infrastructure for $ENVIRONMENT..."
        terraform destroy -var="environment=$ENVIRONMENT" -auto-approve
    fi
    
    cd ../..
}

# Deploy Azure infrastructure
deploy_azure() {
    print_info "Deploying Azure infrastructure..."
    
    # Login to Azure
    az login
    
    cd terraform/azure
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    
    # Plan or Apply
    if [ "$ACTION" == "plan" ]; then
        terraform plan -var="environment=$ENVIRONMENT" -out=tfplan
    elif [ "$ACTION" == "apply" ]; then
        terraform apply -var="environment=$ENVIRONMENT" -auto-approve
        
        # Export outputs
        terraform output -json > ../../outputs/azure-$ENVIRONMENT.json
        print_info "Azure outputs saved to outputs/azure-$ENVIRONMENT.json"
    elif [ "$ACTION" == "destroy" ]; then
        print_warn "Destroying Azure infrastructure for $ENVIRONMENT..."
        terraform destroy -var="environment=$ENVIRONMENT" -auto-approve
    fi
    
    cd ../..
}

# Configure Kubernetes
configure_kubernetes() {
    print_info "Configuring Kubernetes..."
    
    # Get EKS cluster name from Terraform output
    EKS_CLUSTER=$(jq -r '.eks_cluster_name.value' outputs/aws-$ENVIRONMENT.json)
    
    # Update kubeconfig
    aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION
    
    # Create namespace and secrets
    kubectl apply -f k8s/00-namespace.yaml
    
    # Get RDS endpoints from Terraform output
    RDS_ERP=$(jq -r '.rds_erp_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    RDS_CRM=$(jq -r '.rds_crm_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    RDS_SUPPLY=$(jq -r '.rds_supply_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    
    print_info "RDS Endpoints:"
    print_info "  ERP: $RDS_ERP"
    print_info "  CRM: $RDS_CRM"
    print_info "  Supply: $RDS_SUPPLY"
    
    # Deploy infrastructure services (Redis, RabbitMQ)
    kubectl apply -f k8s/redis-deployment.yaml
    kubectl apply -f k8s/rabbitmq-deployment.yaml
    
    # Wait for infrastructure services to be ready
    print_info "Waiting for Redis to be ready..."
    kubectl wait --for=condition=ready pod -l app=redis -n digitrans-cm --timeout=300s
    
    print_info "Waiting for RabbitMQ to be ready..."
    kubectl wait --for=condition=ready pod -l app=rabbitmq -n digitrans-cm --timeout=300s
    
    print_info "Kubernetes infrastructure configured successfully!"
}

# Deploy application services
deploy_services() {
    print_info "Deploying application services..."
    
    # Get ECR registry from AWS account
    ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Get RDS endpoints
    RDS_ERP=$(jq -r '.rds_erp_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    RDS_CRM=$(jq -r '.rds_crm_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    RDS_SUPPLY=$(jq -r '.rds_supply_endpoint.value' outputs/aws-$ENVIRONMENT.json)
    
    # Update deployment manifests with actual values
    for service in erp-service crm-service supply-chain-service bi-service api-gateway; do
        sed -e "s|ECR_REGISTRY|$ECR_REGISTRY|g" \
            -e "s|IMAGE_TAG|latest|g" \
            -e "s|RDS_ERP_ENDPOINT|$RDS_ERP|g" \
            -e "s|RDS_CRM_ENDPOINT|$RDS_CRM|g" \
            -e "s|RDS_SUPPLY_ENDPOINT|$RDS_SUPPLY|g" \
            k8s/$service-deployment.yaml | kubectl apply -f -
    done
    
    print_info "Application services deployed!"
    print_info "Checking deployment status..."
    kubectl get pods -n digitrans-cm
}

# Main execution
main() {
    check_prerequisites
    
    # Create outputs directory
    mkdir -p outputs
    
    case $ACTION in
        plan|apply|destroy)
            deploy_aws
            deploy_azure
            
            if [ "$ACTION" == "apply" ]; then
                configure_kubernetes
                
                print_info ""
                print_info "========================================="
                print_info "Infrastructure deployment completed!"
                print_info "========================================="
                print_info ""
                print_info "Next steps:"
                print_info "1. Configure GitHub Actions secrets"
                print_info "2. Push code to trigger CI/CD pipeline"
                print_info "3. Monitor deployment: kubectl get pods -n digitrans-cm -w"
                print_info ""
                print_info "Access points:"
                ALB_DNS=$(jq -r '.alb_dns_name.value' outputs/aws-$ENVIRONMENT.json)
                print_info "  API Gateway: http://$ALB_DNS"
                print_info "  Swagger UI: http://$ALB_DNS/swagger-ui.html"
                print_info ""
            fi
            ;;
        deploy-services)
            deploy_services
            ;;
        *)
            print_error "Invalid action: $ACTION"
            print_info "Valid actions: plan, apply, destroy, deploy-services"
            exit 1
            ;;
    esac
}

main
