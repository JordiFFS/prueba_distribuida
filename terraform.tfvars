aws_region       = "us-east-1"
instance_type    = "t3.micro"
app_name         = "react-hello-world"
app_port         = 3000
desired_capacity = 2
min_size         = 2
max_size         = 4

# Reemplaza esto con el ID de tu AMI personalizada después de crear con Packer
ami_id = "ami-0f7c7cba8f1878a70"