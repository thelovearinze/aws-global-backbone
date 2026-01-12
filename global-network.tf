# 1. Create the Global Network Container
resource "aws_networkmanager_global_network" "global_mesh" {
  description = "Global Backbone Mesh - Africa and Europe"
  tags        = { Name = "Global-Backbone-Manager" }
}

# 2. Register Ireland Transit Gateway
resource "aws_networkmanager_transit_gateway_registration" "hub_tgw_reg" {
  global_network_id    = aws_networkmanager_global_network.global_mesh.id
  transit_gateway_arn  = aws_ec2_transit_gateway.hub_tgw.arn
}

# 3. Register Africa Transit Gateway
resource "aws_networkmanager_transit_gateway_registration" "africa_tgw_reg" {
  global_network_id    = aws_networkmanager_global_network.global_mesh.id
  transit_gateway_arn  = aws_ec2_transit_gateway.africa_tgw.arn
}
