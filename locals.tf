# =============================================================================
# MikroTik VLAN Module - Local Values
# =============================================================================
# Author: Łukasz Kołodziej (Cloud Architect, Aircloud)
# Project: BCU ZSE Opole
# =============================================================================

locals {
  # Validation: Check all VLANs have valid subnet CIDR notation
  invalid_subnets = [
    for k, v in var.vlans :
    k if !can(cidrhost(v.subnet, 0))
  ]
  
  # VLAN IDs as list for routing and firewall
  vlan_ids = [for k in keys(var.vlans) : tonumber(k)]
  
  # Trunk ports validation
  has_trunk_ports = length(var.trunk_ports) > 0
  
  # Access ports (non-trunk)
  access_ports = [
    for port, pvid in var.pvid_map :
    port if !contains(var.trunk_ports, port)
  ]
}
