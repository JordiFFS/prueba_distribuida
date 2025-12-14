# ============================================================
# MÓDULO AUTO SCALING - SIN IAM ROLE (Compatible con Voclabs)
# ============================================================

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ============================================================
# LAUNCH TEMPLATE
# ============================================================
resource "aws_launch_template" "main" {
  name_prefix   = "${var.app_name}-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_security_group_id]

  # ============================================================
  # USER DATA
  # ============================================================
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    LOG=/var/log/startup.log
    echo "===== STARTUP SCRIPT =====" | tee $LOG

    yum update -y >> $LOG 2>&1
    yum install -y docker curl >> $LOG 2>&1

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    sleep 5

    echo "Ejecutando contenedor..." | tee -a $LOG

    docker run -d \
    --restart always \
    --name react-app \
    -p 3000:3000 \
    jordiffs/react-hello-world:latest

    echo "Contenedores activos:" | tee -a $LOG
    docker ps | tee -a $LOG

    echo "===== SCRIPT FINALIZADO =====" | tee -a $LOG
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.app_name}-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================
# AUTO SCALING GROUP
# ============================================================
resource "aws_autoscaling_group" "main" {
  name                = "${var.app_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
