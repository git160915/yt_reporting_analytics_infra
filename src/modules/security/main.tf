resource "aws_security_group" "instance" {
  name        = "${var.environment}-ec2-private-sg"
  description = "Security group for EC2 instances in ${var.environment}-ec2-private-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Restrict HTTPS as needed (empty here means you'll lock it down elsewhere)
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ec2-private-sg"
  }
}
