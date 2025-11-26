# =============================================================================
# MikroTik VLAN Module
# =============================================================================
# Purpose: Create VLANs on MikroTik bridge and assign IP addresses
# Requirements: RouterOS v7+, bridge already configured
# Usage: See examples/ directory
# =============================================================================

# =============================================================================
# MikroTik VLAN Module - RouterOS 7.17 Compatible
# =============================================================================
# Purpose: Configure VLANs with bridge VLAN filtering
# RouterOS Version: 7.17+
# Last Updated: 2025-11-25
# Architecture: ZSEL + BCU (26 VLANs total)
# =============================================================================

terraform {
  required_providers {
    routeros = {
      source  = "ddelnano/mikrotik"
      version = "~> 0.15"
    }
  }
  required_version = ">= 1.6.0"
}

# =============================================================================
# Input Variables
# =============================================================================

variable "bridge_name" {
  description = "Name of the bridge interface (default: bridge1)"
  type        = string
  default     = "bridge1"
}

variable "enable_vlan_filtering" {
  description = "Enable bridge VLAN filtering (required for trunk/access ports)"
  type        = bool
  default     = true
}

variable "vlans" {
  description = "Map of VLANs to create with subnets and DHCP pools"
  type = map(object({
    name        = string
    subnet      = string
    dhcp_pool_start = optional(string, "")
    dhcp_pool_end   = optional(string, "")
    comment     = optional(string, "")
  }))
}

variable "trunk_ports" {
  description = "List of ports configured as VLAN trunk (tagged all VLANs)"
  type        = list(string)
  default     = []
}

variable "pvid_map" {
  description = "Map of access ports to their PVID (untagged VLAN)"
  type        = map(number)
  default     = {}
}

# =============================================================================
# VLAN Interfaces - RouterOS 7.17 VLAN на bridge
# =============================================================================

resource "routeros_interface_vlan" "vlans" {
  for_each = var.vlans

  name      = "vlan${each.key}"              # e.g., vlan101, vlan110, vlan208
  vlan_id   = tonumber(each.key)             # VLAN ID as integer
  interface = var.bridge_name                # Parent bridge (bridge1)
  mtu       = 1500
  arp       = "enabled"
  comment   = each.value.comment != "" ? each.value.comment : "VLAN ${each.key} - ${each.value.name} | Managed by Terraform"
}

# =============================================================================
# IP Addresses - Gateway IP dla każdego VLAN interface
# =============================================================================\n# RouterOS 7.17: IP Address z network i broadcast calculation\n\nresource \"routeros_ip_address\" \"vlan_gateways\" {\n  for_each = var.vlans\n\n  # Automatyczne wyliczenie gateway IP (pierwszy host w sieci)\n  # Przykłady:\n  # 192.168.1.0/24 → 192.168.1.1/24\n  # 10.208.0.0/16 → 10.208.0.1/16\n  # 172.20.20.0/24 → 172.20.20.1/24\n  address   = \"${cidrhost(each.value.subnet, 1)}/${split(\"/\", each.value.subnet)[1]}\"\n  interface = routeros_interface_vlan.vlans[each.key].name\n  network   = cidrhost(each.value.subnet, 0)  # Network address\n  comment   = \"Gateway ${each.value.name} (VLAN ${each.key})\"\n\n  depends_on = [routeros_interface_vlan.vlans]\n}

# =============================================================================
# Bridge VLAN Filtering - RouterOS 7.17 Enhanced
# =============================================================================
# Purpose: Configure tagged (trunk) and untagged (access) ports
# Topology: CCR → CRS518 (trunk 40G) → CRS354 (trunk 10G) → endpoints (access 1G)

resource "routeros_interface_bridge_vlan" "vlan_filter" {
  for_each = var.enable_vlan_filtering ? var.vlans : {}

  bridge   = var.bridge_name
  vlan_ids = [tonumber(each.key)]
  
  # Tagged ports (trunk): allow all VLANs
  # CCR2216: sfp-sfpplus1-8 (uplinks to CRS518)
  # CRS518: qsfp28plus1-2 (uplinks to CCR), sfp28-1-24 (downlinks to CRS354)
  tagged   = var.trunk_ports
  
  # Untagged ports (access): assigned via PVID
  # Configured per-port in pvid_map variable
  untagged = [
    for port, pvid in var.pvid_map :
    port if pvid == tonumber(each.key)
  ]
  
  comment = "VLAN ${each.key} filtering | ${each.value.name}"

  depends_on = [routeros_interface_vlan.vlans]
}

# =============================================================================
# Bridge Port PVID - Set default VLAN for access ports
# =============================================================================
# RouterOS 7.17: PVID must be set on bridge ports for untagged traffic

resource "routeros_interface_bridge_port" "port_pvid" {
  for_each = var.pvid_map

  interface = each.key
  bridge    = var.bridge_name
  pvid      = each.value
  
  # Security: frame-types=admit-only-vlan-tagged for trunk ports
  frame_types = contains(var.trunk_ports, each.key) ? "admit-all" : "admit-only-untagged-and-priority-tagged"
  
  # Ingress filtering prevents VLAN hopping
  ingress_filtering = true
  
  comment = "Port ${each.key} PVID=${each.value} | Terraform managed"

  depends_on = [routeros_interface_bridge_vlan.vlan_filter]
}

# =============================================================================
# Outputs - Informacje o utworzonych VLANach
# =============================================================================

output "vlan_interfaces" {
  description = "Created VLAN interfaces with IDs and names"
  value = {
    for k, v in routeros_interface_vlan.vlans : k => {
      name    = v.name
      vlan_id = v.vlan_id
      subnet  = var.vlans[k].subnet
      comment = v.comment
    }
  }
}

output "vlan_gateways" {
  description = "Gateway IP addresses for each VLAN (computed from subnets)"
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
  value       = [for k in keys(var.vlans) : tonumber(k)]
}

# =============================================================================
# Validation - Sprawdzenie poprawności konfiguracji
# =============================================================================

# Check: All VLANs have valid subnet CIDR notation
locals {
  invalid_subnets = [
    for k, v in var.vlans :
    k if !can(cidrhost(v.subnet, 0))
  ]
}

output "validation_errors" {
  description = "Configuration validation errors (empty = OK)"
  value = {
    invalid_subnets = length(local.invalid_subnets) > 0 ? local.invalid_subnets : []
    warning = length(local.invalid_subnets) > 0 ? "FIX: Invalid subnet CIDR notation detected!" : "Configuration valid"
  }
}

# =============================================================================
# Example Usage
# =============================================================================
# module "routeros_vlans" {
#   source = "./modules/mikrotik/vlans"
#
#   bridge_name = "bridge1"
#   vlans = {
#     "10" = {
#       name   = "K3s-Cluster"
#       subnet = "192.168.10.0/24"
#     }
#     "20" = {
#       name   = "Storage"
#       subnet = "192.168.20.0/24"
#     }
#   }
# }
