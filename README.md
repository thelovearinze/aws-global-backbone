# AWS Global Backbone: Multi-Region Hub-and-Spoke Mesh

## Project Vision
This project architects a high-availability global backbone connecting Dublin, Ireland (eu-west-1) and Cape Town, South Africa (af-south-1). By leveraging the private AWS Global Accelerator backbone via Transit Gateway Peering, this architecture eliminates the latency and security risks associated with the public internet for cross-continental workloads.



## Technical Stack
* Cloud Provider: AWS (Global Infrastructure)
* Infrastructure as Code: Terraform (HCL)
* Networking: Transit Gateway, VPC Peering, NAT Gateways
* Security: State-aware Security Groups & Network ACLs

## Key Architectural Decisions
* Regional Opt-in Logic: Managed the unique requirement of the Cape Town region (af-south-1), which requires explicit account-level enablement and specific provider aliasing in Terraform.
* Symmetric Routing: Manually engineered the return paths in the Africa Spoke VPC to ensure traffic from Ireland could successfully traverse the peering attachment back to the source.
* Cost Optimization: Implemented a "destroy-on-idle" policy to manage NAT Gateway and Inter-Region data transfer costs effectively.

## Specialist Insights and Troubleshooting
During deployment, I identified and resolved two significant real-world challenges:
1. Reachability Analyzer Limitations: Identified that automated trace tools hit regional boundaries at the peering attachment. I successfully verified the path using manual Control Plane audits (CLI-based route table inspections).
2. Service Entitlement Scaling: Diagnosed a SubscriptionRequiredException in the Global Network Manager. I managed a professional escalation to AWS Support to resolve a backend account-level service handshake issue.

## How to Deploy
1. git clone https://github.com/thelovearinze/aws-global-backbone.git
2. terraform init
3. terraform apply -auto-approve
