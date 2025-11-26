# =============================================================================
# MikroTik VLAN Module - Outputs
# =============================================================================
# Author: Łukasz Kołodziej (Cloud Architect, Aircloud)
# Project: BCU ZSE Opole
# =============================================================================

output "vlan_interfaces" {
  description = "Created VLAN interfaces with IDs and names"
  value = {
    for k, v in routeros_interface_vlan.vlans : k => {
      name    = v.name
      vlan_id = v.vlan_id
      subnet  = var.vlans[k].subnet
    }
  }
}

output "vlan_gateways" {
  description = "Gateway IP addresses for each VLAN"
  value = {
    for k, v in var.vlans : k => {
      gateway = cidrhost(v.subnet, 1)
      subnet  = v.subnet
      vlan_id = k
    }
  }
}

output "vlan_summary" {
  description = "Summary of VLAN configuration"
  value = {
    total_vlans        = length(var.vlans)
    bridge_name        = var.bridge_name
    vlan_filtering     = var.enable_vlan_filtering
    trunk_ports_count  = length(var.trunk_ports)
    access_ports_count = length(var.pvid_map)
  }
}

output "vlan_list" {
  description = "List of VLAN IDs for use in other modules"
  value       = local.vlan_ids
}

output "validation_errors" {
  description = "Configuration validation errors (empty = OK)"
  value = {
    invalid_subnets = length(local.invalid_subnets) > 0 ? local.invalid_subnets : []
    warning = length(local.invalid_subnets) > 0 ? "FIX: Invalid subnet CIDR notation!" : "Configuration valid"
  }
}
