#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Script de Despliegue: React + Docker + EC2 + ALB + Terraform ===${NC}\n"

# 1. Crear repositorio ECR
echo -e "${YELLOW}Paso 1: Creando repositorio ECR...${NC}"
REPO_NAME="react-hello-world"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"

if aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION 2>/dev/null; then
  echo -e "${GREEN}Repositorio ECR ya existe${NC}"
else
  aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION
  echo -e "${GREEN}Repositorio ECR creado${NC}"
fi

# 2. Login a ECR
echo -e "${YELLOW}Paso 2: Login a ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo -e "${GREEN}Login exitoso${NC}\n"

# 3. Construir imagen Docker
echo -e "${YELLOW}Paso 3: Construyendo imagen Docker...${NC}"
docker build -t $REPO_NAME:latest .
echo -e "${GREEN}Imagen construida${NC}\n"

# 4. Tagear imagen para ECR
echo -e "${YELLOW}Paso 4: Tageando imagen para ECR...${NC}"
docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
echo -e "${GREEN}Imagen tageada${NC}\n"

# 5. Push a ECR
echo -e "${YELLOW}Paso 5: Subiendo imagen a ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
echo -e "${GREEN}Imagen subida a ECR${NC}\n"

# 6. Crear AMI con Packer
echo -e "${YELLOW}Paso 6: Creando AMI personalizada con Packer...${NC}"
if command -v packer &> /dev/null; then
  packer init .
  packer build packer.pkr.hcl
  
  # Obtener el ID de la AMI creada
  AMI_ID=$(aws ec2 describe-images --owners self --query 'Images[0].ImageId' --output text --region $AWS_REGION)
  echo -e "${GREEN}AMI creada con ID: $AMI_ID${NC}\n"
  
  # Actualizar terraform.tfvars con el AMI_ID
  sed -i "s/ami_id = \"ami-xxxxxxxxx\"/ami_id = \"$AMI_ID\"/" terraform.tfvars
  echo -e "${GREEN}terraform.tfvars actualizado${NC}\n"
else
  echo -e "${RED}Packer no está instalado. Instálalo desde: https://www.packer.io/downloads${NC}"
  echo -e "${YELLOW}Deberás crear la AMI manualmente o instalar Packer${NC}\n"
  
  echo -e "${YELLOW}Para crear la AMI manualmente:${NC}"
  echo "1. Lanza una instancia EC2 de Amazon Linux 2"
  echo "2. SSH a la instancia y ejecuta los comandos de instalación de Packer"
  echo "3. Crea una AMI desde la instancia parada"
  echo "4. Actualiza ami_id en terraform.tfvars\n"
fi

# 7. Inicializar Terraform
echo -e "${YELLOW}Paso 7: Inicializando Terraform...${NC}"
cd terraform || mkdir terraform && cd terraform
terraform init
echo -e "${GREEN}Terraform inicializado${NC}\n"

# 8. Plan de Terraform
echo -e "${YELLOW}Paso 8: Generando plan de Terraform...${NC}"
terraform plan -out=tfplan
echo -e "${GREEN}Plan generado${NC}\n"

# 9. Aplicar Terraform
echo -e "${YELLOW}Paso 9: Aplicando configuración de Terraform...${NC}"
read -p "¿Deseas aplicar la configuración de Terraform? (si/no): " response
if [ "$response" = "si" ] || [ "$response" = "yes" ]; then
  terraform apply tfplan
  
  ALB_DNS=$(terraform output -raw alb_dns_name)
  echo -e "${GREEN}¡Despliegue completado!${NC}"
  echo -e "${GREEN}Tu aplicación está disponible en: http://$ALB_DNS${NC}\n"
else
  echo -e "${YELLOW}Despliegue cancelado${NC}"
fi

echo -e "${GREEN}=== Script completado ===${NC}"