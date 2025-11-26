# =============================================================================
# MikroTik VLAN Module - VLAN Resources
# =============================================================================
# Author: Łukasz Kołodziej (Cloud Architect, Aircloud)
# Project: BCU ZSE Opole
# =============================================================================

# =============================================================================
# VLAN Interfaces - RouterOS 7.17+
# =============================================================================

resource "routeros_interface_vlan" "vlans" {
  for_each = var.vlans

  name      = "vlan${each.key}"
  vlan_id   = tonumber(each.key)
  interface = var.bridge_name
  mtu       = 1500
}

# =============================================================================
# IP Addresses - Gateway for each VLAN
# =============================================================================

resource "routeros_ip_address" "vlan_gateways" {
  for_each = var.vlans

  # Compute gateway IP (first host in subnet)
  # Examples: 192.168.1.0/24 → 192.168.1.1/24
  address   = "${cidrhost(each.value.subnet, 1)}/${split("/", each.value.subnet)[1]}"
  interface = routeros_interface_vlan.vlans[each.key].name
  network   = cidrhost(each.value.subnet, 0)
  comment   = "Gateway ${each.value.name} (VLAN ${each.key})"

  depends_on = [routeros_interface_vlan.vlans]
}
