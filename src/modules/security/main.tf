resource "aws_security_group" "instance" {
  name        = var.security_group_name
  description = "Security group for EC2 instances in ${var.security_group_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Restrict SSH as needed (empty here means you'll lock it down elsewhere)
    cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}
