provider "aws" {
  region = "us-east-1"
}

# Generate an SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/dave-key.pem"
}

# Save the public key locally
resource "local_file" "public_key" {
  content  = tls_private_key.example.public_key_openssh
  filename = "${path.module}/dave-key.pub"
}

# Create the AWS key pair
resource "aws_key_pair" "deployer" {
  key_name   = "dave-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Create a security group with the necessary inbound rules
resource "aws_security_group" "app_sg" {
  name        = "app_security_group"
  description = "Allow SSH, HTTP, and HTTPS traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_security_group"
  }
}

# Create EC2 instances
resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-0195204d5dce06d99"  # Replace with a valid AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "AppInstance-${count.index + 1}"
  }
}

# Create an ELB
resource "aws_elb" "app_lb" {
  name               = "app-load-balancer"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = aws_instance.app[*].id

  tags = {
    Name = "AppLoadBalancer"
  }
}


# Local exec to move the key to .ssh and set permissions
resource "null_resource" "configure_ssh" {
  provisioner "local-exec" {
    command = <<EOT
      mv ${path.module}/dave-key.pem ~/.ssh/dave-key.pem
      chmod 400 ~/.ssh/dave-key.pem
    EOT
  }

  depends_on = [local_file.private_key]
}
