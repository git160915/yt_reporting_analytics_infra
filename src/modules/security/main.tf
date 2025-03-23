resource "aws_security_group" "instance" {
  name        = "ec2-private-sg"
  description = "Allow necessary internal traffic"
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
}
