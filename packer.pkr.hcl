packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

source "amazon-ebs" "react_app" {
  ami_name      = "react-hello-world-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  ssh_username = "ec2-user"
  ami_description = "AMI personalizada con Docker y Docker Compose para React Vite"
  
  tags = {
    Name = "react-hello-world-ami"
    App  = "react-hello-world"
  }
}

build {
  name = "react-hello-world-ami"
  sources = [
    "source.amazon-ebs.react_app"
  ]

  provisioner "shell" {
    inline = [
      "echo 'Actualizando sistema...'",
      "sudo yum update -y",
      "echo 'Instalando Docker...'",
      "sudo amazon-linux-extras install docker -y",
      "echo 'Instalando Docker Compose...'",
      "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "echo 'Iniciando Docker...'",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "echo 'Agregando usuario ec2-user al grupo docker...'",
      "sudo usermod -aG docker ec2-user",
      "echo 'Instalando CloudWatch agent...'",
      "wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",
      "sudo rpm -U ./amazon-cloudwatch-agent.rpm",
      "echo 'AMI lista!'"
    ]
  }

  provisioner "file" {
    content = <<-EOF
#!/bin/bash
set -e

# Obtener el secret del Parameter Store o ambiente
ECR_IMAGE=$${ECR_IMAGE:-"react-hello-world:latest"}

# Crear directorio para logs
mkdir -p /var/log/react-app

# Iniciar la aplicación
docker run -d \
  --restart always \
  -p 3000:3000 \
  --name react-app \
  --log-driver awslogs \
  --log-opt awslogs-group=/aws/ec2/react-app \
  --log-opt awslogs-region=$${AWS_REGION:-us-east-1} \
  --log-opt awslogs-stream-prefix=ecs \
  $${ECR_IMAGE}

echo "Aplicación iniciada"
EOF
    destination = "/home/ec2-user/start-app.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /home/ec2-user/start-app.sh",
      "sudo chown root:root /home/ec2-user/start-app.sh"
    ]
  }
}