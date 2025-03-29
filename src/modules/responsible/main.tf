data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "responsible_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.responsible_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    # Optionally set the hop limit (default is 1; increase if needed)
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y python3 amazon-ssm-agent
              # Start the SSM Agent service and enable it to start on boot
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              echo "print('Hello from Responsible Instance')" > /home/ec2-user/responsible.py
              EOF

  tags = {
    Name = "${var.environment}-ResponsibleInstance"
  }
}
