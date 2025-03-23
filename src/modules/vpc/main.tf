resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
}

resource "aws_subnet" "responsible" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
}

data "aws_availability_zones" "available" {}