# 1. Get Latest Amazon Linux 2 AMI for Ireland
data "aws_ami" "hub_ami" {
  provider    = aws.hub
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. Get Latest Amazon Linux 2 AMI for Africa
data "aws_ami" "africa_ami" {
  provider    = aws.africa
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 3. Test Instance in Ireland Hub
resource "aws_instance" "hub_instance" {
  provider               = aws.hub
  ami                    = data.aws_ami.hub_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.hub_private.id
  vpc_security_group_ids = [aws_security_group.hub_sg.id]
  tags = { Name = "Hub-Test-Instance" }
}

# 4. Test Instance in Africa Spoke
resource "aws_instance" "africa_instance" {
  provider               = aws.africa
  ami                    = data.aws_ami.africa_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.africa_private.id
  vpc_security_group_ids = [aws_security_group.africa_sg.id]
  tags = { Name = "Africa-Test-Instance" }
}

# 5. Output the Private IPs for testing
output "hub_instance_private_ip" {
  value = aws_instance.hub_instance.private_ip
}

output "africa_instance_private_ip" {
  value = aws_instance.africa_instance.private_ip
}
