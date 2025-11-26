# =============================================================================
# MikroTik VLAN Module - Bridge VLAN Filtering
# =============================================================================
# Author: Łukasz Kołodziej (Cloud Architect, Aircloud)
# Project: BCU ZSE Opole
# =============================================================================

# =============================================================================
# Bridge VLAN Filtering - Tagged/Untagged Ports
# =============================================================================
# Topology:
# - QSFP28 100Gb: CCR ↔ CRS518 (Core)
# - SFP+ 10Gb: PD ↔ KPD (Distribution to endpoints)
# =============================================================================

resource "routeros_interface_bridge_vlan" "vlan_filter" {
  for_each = var.enable_vlan_filtering ? var.vlans : {}

  bridge   = var.bridge_name
  vlan_ids = [tonumber(each.key)]
  
  # Tagged ports (trunk): all VLANs allowed
  tagged   = var.trunk_ports
  
  # Untagged ports (access): assigned via PVID
  untagged = [
    for port, pvid in var.pvid_map :
    port if pvid == tonumber(each.key)
  ]

  depends_on = [routeros_interface_vlan.vlans]
}

# =============================================================================
# Bridge Port PVID - Access Port Configuration
# =============================================================================

resource "routeros_interface_bridge_port" "port_pvid" {
  for_each = var.pvid_map

  interface = each.key
  bridge    = var.bridge_name
  pvid      = each.value
  
  # Frame types: trunk allows all, access only untagged
  frame_types = contains(var.trunk_ports, each.key) ? "admit-all" : "admit-only-untagged-and-priority-tagged"
  
  # Ingress filtering prevents VLAN hopping
  ingress_filtering = true
  
  comment = "Port ${each.key} PVID=${each.value} | Terraform managed"

  depends_on = [routeros_interface_bridge_vlan.vlan_filter]
}
