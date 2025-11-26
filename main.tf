# =============================================================================
# MikroTik VLAN Module - RouterOS 7.17 Compatible
# =============================================================================
# Purpose: Configure VLANs with bridge VLAN filtering
# RouterOS Version: 7.17+
# Last Updated: 2025-11-27
# Architecture: ZSEL + BCU (31 VLANs total)
# =============================================================================
# Module structure:
#   - versions.tf: Terraform and provider requirements
#   - variables.tf: Input variable definitions
#   - locals.tf: Local value computations and validations
#   - vlans.tf: VLAN interface and IP address resources
#   - bridge.tf: Bridge VLAN filtering and port PVID configuration
#   - outputs.tf: Module outputs
# =============================================================================

# All resources have been moved to separate files for better organization.
# This file serves as the main entry point and documentation.

# =============================================================================
# Example Usage
# =============================================================================
# module "routeros_vlans" {
#   source = "./zsel-eip-tf-module-mikrotik-vlans"
#
#   bridge_name           = "bridge1"
#   enable_vlan_filtering = true
#   
#   vlans = {
#     "10" = {
#       name   = "K3s-Control-Plane"
#       subnet = "10.10.10.0/24"
#     }
#     "20" = {
#       name   = "K3s-Workers"
#       subnet = "10.10.20.0/24"
#     }
#   }
#   
#   trunk_ports = ["qsfp28-1-1", "qsfp28-1-2"]
#   
#   pvid_map = {
#     "ether10" = 10
#     "ether20" = 20
#   }
# }
