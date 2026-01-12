# Create the Hub VPC in Ireland
resource "aws_vpc" "hub_vpc" {
  provider             = aws.hub
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "Global-Hub-VPC"
    Project     = "Advanced-Networking-Specialty"
    Environment = "Production"
  }
}

# 1. Public Subnet
resource "aws_subnet" "hub_public" {
  provider          = aws.hub
  vpc_id            = aws_vpc.hub_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "eu-west-1a"
  tags = { Name = "Hub-Public-AZ1" }
}

# 2. Private Subnet
resource "aws_subnet" "hub_private" {
  provider          = aws.hub
  vpc_id            = aws_vpc.hub_vpc.id
  cidr_block        = "10.100.10.0/24"
  availability_zone = "eu-west-1a"
  tags = { Name = "Hub-Private-AZ1" }
}

# 3. Transit Subnet (Dedicated for TGW)
resource "aws_subnet" "hub_transit" {
  provider          = aws.hub
  vpc_id            = aws_vpc.hub_vpc.id
  cidr_block        = "10.100.20.0/24"
  availability_zone = "eu-west-1a"
  tags = { Name = "Hub-Transit-AZ1" }
}

# 1. Internet Gateway
resource "aws_internet_gateway" "hub_igw" {
  provider = aws.hub
  vpc_id   = aws_vpc.hub_vpc.id
  tags     = { Name = "Hub-IGW" }
}

# 2. Public Route Table
resource "aws_route_table" "hub_public_rt" {
  provider = aws.hub
  vpc_id   = aws_vpc.hub_vpc.id
  tags     = { Name = "Hub-Public-RT" }
}

# 3. Default Route to Internet
resource "aws_route" "hub_public_internet_route" {
  provider               = aws.hub
  route_table_id         = aws_route_table.hub_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub_igw.id
}

# 4. Associate Public Subnet with Route Table
resource "aws_route_table_association" "hub_public_assoc" {
  provider       = aws.hub
  subnet_id      = aws_subnet.hub_public.id
  route_table_id = aws_route_table.hub_public_rt.id
}

# 1. Allocate Elastic IP for NAT Gateway
resource "aws_eip" "hub_nat_eip" {
  provider = aws.hub
  domain   = "vpc"
  tags     = { Name = "Hub-NAT-EIP" }
}

# 2. Create NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "hub_nat_gw" {
  provider      = aws.hub
  allocation_id = aws_eip.hub_nat_eip.id
  subnet_id     = aws_subnet.hub_public.id
  tags          = { Name = "Hub-NAT-GW" }

  # To ensure proper ordering, it is best practice to depend on the IGW
  depends_on = [aws_internet_gateway.hub_igw]
}

# 3. Private Route Table
resource "aws_route_table" "hub_private_rt" {
  provider = aws.hub
  vpc_id   = aws_vpc.hub_vpc.id
  tags     = { Name = "Hub-Private-RT" }
}

# 4. Route Private Traffic to NAT Gateway
resource "aws_route" "hub_private_nat_route" {
  provider               = aws.hub
  route_table_id         = aws_route_table.hub_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub_nat_gw.id
}

# 5. Associate Private Subnet with Route Table
resource "aws_route_table_association" "hub_private_assoc" {
  provider       = aws.hub
  subnet_id      = aws_subnet.hub_private.id
  route_table_id = aws_route_table.hub_private_rt.id
}

# 1. Africa Spoke VPC (Cape Town)
resource "aws_vpc" "africa_spoke" {
  provider             = aws.africa
  cidr_block           = "10.101.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "Africa-Spoke-VPC"
    Project     = "Advanced-Networking-Specialty"
    Environment = "Production"
  }
}

# 2. Africa Private Subnet
resource "aws_subnet" "africa_private" {
  provider          = aws.africa
  vpc_id            = aws_vpc.africa_spoke.id
  cidr_block        = "10.101.10.0/24"
  availability_zone = "af-south-1a"
  tags = { Name = "Africa-Private-AZ1" }
}

# 3. Africa Transit Subnet (For TGW Attachment)
resource "aws_subnet" "africa_transit" {
  provider          = aws.africa
  vpc_id            = aws_vpc.africa_spoke.id
  cidr_block        = "10.101.20.0/24"
  availability_zone = "af-south-1a"
  tags = { Name = "Africa-Transit-AZ1" }
}

# 1. Transit Gateway in Ireland (Hub)
resource "aws_ec2_transit_gateway" "hub_tgw" {
  provider    = aws.hub
  description = "Main Hub Transit Gateway"
  tags        = { Name = "Hub-TGW" }
}

# 2. Transit Gateway in Africa (Spoke)
resource "aws_ec2_transit_gateway" "africa_tgw" {
  provider    = aws.africa
  description = "Africa Spoke Transit Gateway"
  tags        = { Name = "Africa-TGW" }
}

# 3. Attach Hub VPC to Hub TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "hub_tgw_attach" {
  provider           = aws.hub
  subnet_ids         = [aws_subnet.hub_transit.id]
  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.hub_vpc.id
  tags               = { Name = "Hub-TGW-Attachment" }
}

# 4. Attach Africa VPC to Africa TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "africa_tgw_attach" {
  provider           = aws.africa
  subnet_ids         = [aws_subnet.africa_transit.id]
  transit_gateway_id = aws_ec2_transit_gateway.africa_tgw.id
  vpc_id             = aws_vpc.africa_spoke.id
  tags               = { Name = "Africa-TGW-Attachment" }
}

# 1. Initiate Peering Request from Ireland (Hub) to Africa (Spoke)
resource "aws_ec2_transit_gateway_peering_attachment" "hub_to_africa_peering" {
  provider                = aws.hub
  peer_region             = "af-south-1"
  peer_transit_gateway_id = aws_ec2_transit_gateway.africa_tgw.id
  transit_gateway_id      = aws_ec2_transit_gateway.hub_tgw.id

  tags = {
    Name = "TGW-Peering-Ireland-to-Africa"
  }
}

# 2. Accept the Peering Request in Africa (Spoke)
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "africa_accepter" {
  provider                      = aws.africa
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_africa_peering.id

  tags = {
    Name = "TGW-Peering-Acceptance-Africa"
  }
}

# 1. Route in Ireland TGW: "To get to Africa (10.101.x.x), use the Peering Attachment"
resource "aws_ec2_transit_gateway_route" "hub_to_africa_route" {
  provider                       = aws.hub
  destination_cidr_block         = "10.101.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.hub_to_africa_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hub_tgw.propagation_default_route_table_id
}

# 2. Route in Africa TGW: "To get to Ireland (10.100.x.x), use the Peering Attachment"
resource "aws_ec2_transit_gateway_route" "africa_to_hub_route" {
  provider                       = aws.africa
  destination_cidr_block         = "10.100.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.hub_to_africa_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.africa_tgw.propagation_default_route_table_id
}

# 1. Update Ireland Hub Route: "To reach Africa (10.101.x.x), go to the Hub TGW"
resource "aws_route" "hub_to_africa_vpc_route" {
  provider               = aws.hub
  route_table_id         = aws_route_table.hub_private_rt.id
  destination_cidr_block = "10.101.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.hub_tgw.id
}

# 2. Create Route Table for Africa Spoke
resource "aws_route_table" "africa_private_rt" {
  provider = aws.africa
  vpc_id   = aws_vpc.africa_spoke.id
  tags     = { Name = "Africa-Private-RT" }
}

# 3. Update Africa Route: "To reach Ireland (10.100.x.x), go to the Africa TGW"
resource "aws_route" "africa_to_hub_vpc_route" {
  provider               = aws.africa
  route_table_id         = aws_route_table.africa_private_rt.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.africa_tgw.id
}

# 4. Associate Africa Private Subnet with the new Route Table
resource "aws_route_table_association" "africa_private_assoc" {
  provider       = aws.africa
  subnet_id      = aws_subnet.africa_private.id
  route_table_id = aws_route_table.africa_private_rt.id
}

# 1. Security Group in Ireland Hub
resource "aws_security_group" "hub_sg" {
  provider    = aws.hub
  name        = "Hub-Global-Allow-SG"
  description = "Allow traffic from Africa Spoke"
  vpc_id      = aws_vpc.hub_vpc.id

  # Allow Ping (ICMP) from Africa
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.101.0.0/16"]
  }

  # Allow SSH from Africa
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.101.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Hub-Global-SG" }
}

# 2. Security Group in Africa Spoke
resource "aws_security_group" "africa_sg" {
  provider    = aws.africa
  name        = "Africa-Global-Allow-SG"
  description = "Allow traffic from Ireland Hub"
  vpc_id      = aws_vpc.africa_spoke.id

  # Allow Ping (ICMP) from Ireland
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.100.0.0/16"]
  }

  # Allow SSH from Ireland
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
