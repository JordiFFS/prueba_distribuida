# React Hello World - Despliegue en AWS con EC2, ALB y Terraform

Este proyecto contiene todo lo necesario para desplegar una aplicación React + Vite en AWS usando EC2 con un Application Load Balancer y Auto Scaling.

## Requisitos previos

- Cuenta de AWS con credenciales configuradas
- Docker instalado localmente
- Terraform >= 1.0
- Packer >= 1.8 (opcional, pero recomendado)
- AWS CLI configurado
- Node.js 18+ (para desarrollo local)

## Estructura del proyecto

```
.
├── src/
│   ├── App.jsx              # Componente principal React
│   ├── App.css
│   └── main.jsx
├── Dockerfile               # Dockerfile para construir la imagen
├── docker-compose.yml       # Docker Compose para pruebas locales
├── packer.pkr.hcl          # Configuración de Packer para crear AMI
├── terraform/
│   └── main.tf              # Configuración de Terraform para AWS
├── terraform.tfvars         # Variables de Terraform
├── deploy.sh                # Script de despliegue automatizado
└── package.json
```

## Paso 1: Preparar el proyecto localmente

```bash
# Clonar o crear el proyecto
npm create vite@latest . -- --template react
npm install

# Probar localmente
npm run dev
```

## Paso 2: Probar con Docker localmente

```bash
# Construir la imagen Docker
docker build -t react-hello-world:latest .

# Ejecutar con Docker Compose
docker-compose up

# La aplicación estará en http://localhost:3000
```

## Paso 3: Crear la AMI personalizada

### Opción A: Usar Packer (Automatizado - Recomendado)

```bash
# Instalar Packer si no lo tienes
# macOS
brew install packer

# Linux
wget https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_linux_amd64.zip
unzip packer_1.8.0_linux_amd64.zip
sudo mv packer /usr/local/bin/

# Crear la AMI
packer init .
packer build packer.pkr.hcl

# El proceso tardará 5-10 minutos
```

Después de que Packer termine, copia el ID de la AMI creada.

### Opción B: Crear AMI manualmente

1. Lanza una instancia EC2 de Amazon Linux 2 (t3.micro)
2. SSH a la instancia:
   ```bash
   ssh -i tu-key.pem ec2-user@tu-ip-publica
   ```
3. Ejecuta los comandos de instalación:
   ```bash
   sudo yum update -y
   sudo amazon-linux-extras install docker -y
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker ec2-user
   ```
4. Detén la instancia desde la consola de AWS
5. Clic derecho > Image and templates > Create image
6. Copia el ID de la AMI creada

## Paso 4: Configurar variables de Terraform

Edita `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
instance_type    = "t3.micro"
app_name         = "react-hello-world"
app_port         = 3000
desired_capacity = 2
min_size         = 2
max_size         = 4
ami_id           = "ami-0c55b159cbfafe1f0"  # Reemplaza con tu AMI ID
```

## Paso 5: Subir imagen a ECR

```bash
# Obtener el ID de tu cuenta AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"

# Crear repositorio ECR
aws ecr create-repository --repository-name react-hello-world --region $AWS_REGION

# Login a ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Construir y tagear
docker build -t react-hello-world:latest .
docker tag react-hello-world:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/react-hello-world:latest

# Subir a ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/react-hello-world:latest
```

## Paso 6: Desplegar con Terraform

### Opción A: Script automatizado

```bash
chmod +x deploy.sh
./deploy.sh
```

### Opción B: Manualmente

```bash
cd terraform

# Inicializar Terraform
terraform init

# Verificar el plan
terraform plan

# Aplicar la configuración
terraform apply

# Obtener la URL del ALB
terraform output alb_dns_name
```

## Paso 7: Acceder a la aplicación

Una vez que Terraform termine, obtendrás la URL del ALB:

```bash
terraform output alb_dns_name
```

Abre en tu navegador: `http://tu-alb-dns.elb.amazonaws.com`

## Recursos creados

- **VPC**: Red virtual aislada
- **Subnets**: 2 subnets públicas en diferentes AZs
- **Internet Gateway**: Para acceso a internet
- **Application Load Balancer**: Distribuye tráfico
- **Auto Scaling Group**: Escala automáticamente basado en CPU
- **Launch Template**: Configuración para lanzar instancias
- **Security Groups**: Controles de firewall
- **CloudWatch Alarms**: Monitoreo automático

## Monitoreo y Logs

### Ver logs de CloudWatch

```bash
aws logs tail /aws/ec2/react-app --follow
```

### Ver métricas de EC2

1. Ve a AWS Console > EC2 > Instances
2. Selecciona una instancia
3. Haz clic en "Monitoring"

### Ver estado del ALB

```bash
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
```

## Escalado automático

El Auto Scaling Group está configurado para:

- **Scale Up**: Cuando CPU > 70% por 2 períodos (10 minutos)
- **Scale Down**: Cuando CPU < 30% por 2 períodos (10 minutos)
- **Mínimo**: 2 instancias
- **Máximo**: 4 instancias

## Costos estimados

Con t3.micro (eligible para free tier):

- 2-4 instancias EC2: ~$5-15/mes
- Application Load Balancer: ~$16/mes
- Transferencia de datos: Depende del uso
- **Total estimado**: $25-40/mes (sin free tier)

## Limpiar recursos

Para evitar cargos, destruye los recursos cuando termines:

```bash
cd terraform
terraform destroy
```

Confirma escribiendo `yes`.

## Solución de problemas

### Las instancias no inician
- Verifica que el AMI ID sea válido
- Comprueba que tienes suficientes límites de instancias EC2

### El ALB no recibe tráfico
- Verifica security groups permitan puerto 80
- Comprueba health checks en Target Group
- Revisa logs de CloudWatch

### Errores de Terraform
```bash
terraform refresh
terraform plan
```

### Docker no inicia en instancia
SSH a la instancia y verifica:
```bash
sudo systemctl status docker
sudo docker ps
```

## Mejoras futuras

- Agregar HTTPS con ACM Certificate
- Configurar auto-scaling basado en solicitudes HTTP
- Agregar RDS para base de datos
- Configurar CI/CD con CodePipeline
- Agregar WAF para seguridad

## Soporte

Para más información:
- [Documentación de Terraform AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS vs EC2](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [Best practices de ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

---

**Creado**: Diciembre 2024
**Última actualización**: Diciembre 2024