provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app" {
  count = 2
  ami           = "ami-0195204d5dce06d99"  # Replace with a valid AMI ID
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "AppInstance-${count.index + 1}"
  }
}

resource aws_key_pair "deployer" {
  key_name   = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcIK6+wfx0AF/avrp6dg9E7pSWXIqeH+Bwi39hAAFTKz25j6wGEuoa1Ts98w3th1YtvS6963W9ATjcwooKCTd1glJpp8wDUH/+AQSz8lFmgKm951fKsrYp7az098v9v6xtHfEN05W39gyZS9fLYhbZ6Qus0NFTIBhacJ1KUILqbAYlNXo5/Smxd9MKHY0FIhnnbxJMIhvJ+h/FgGojvUzCPmWosHLg37+hYA8vUfJFiPpQihiBgeAHCTEwnHYFkqxmOzWymrQgo1L4A7qaNtVGCQWDF5kETTDygdk99tahUxYzYEre/8k45g/STq/SK58rLJojprmZj8LNBPDbQMAN modouceesay@Momodous-MacBook-Pro.local"

  tags = {
    Name = "EC2_Tutorial"
  }
}

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
