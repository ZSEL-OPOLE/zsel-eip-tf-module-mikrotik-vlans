# =============================================================================
# MikroTik VLAN Module - Variables
# =============================================================================
# Author: Łukasz Kołodziej (Cloud Architect, Aircloud)
# Project: BCU ZSE Opole
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
