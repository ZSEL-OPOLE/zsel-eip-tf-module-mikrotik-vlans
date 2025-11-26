# =============================================================================
# MikroTik VLAN Module - Basic Functionality Tests
# =============================================================================

# Mock provider configuration for testing without real RouterOS device
mock_provider "routeros" {}

# Test 1: Single VLAN creation
run "single_vlan" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "101" = {
        name    = "Dydaktyczna-P0"
        subnet  = "192.168.1.0/24"
        comment = "Sieć dydaktyczna parter"
      }
    }
    enable_vlan_filtering = false
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["101"].vlan_id == 101
    error_message = "VLAN ID should be 101"
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["101"].interface == "bridge1"
    error_message = "VLAN should be attached to bridge1"
  }
}

# Test 2: VLAN with gateway IP
run "vlan_with_gateway" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "500" = {
        name    = "Administracyjna"
        subnet  = "172.20.20.0/24"
        comment = "Sieć administracyjna"
      }
    }
  }
  
  assert {
    condition     = can(regex("^172\\.20\\.20\\.1/24$", routeros_ip_address.vlan_gateways["500"].address))
    error_message = "Gateway IP should be 172.20.20.1/24"
  }
}

# Test 3: Multiple VLANs
run "multiple_vlans" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "101" = {
        name   = "Dydaktyczna-P0"
        subnet = "192.168.1.0/24"
      }
      "110" = {
        name   = "Telewizory"
        subnet = "192.168.10.0/24"
      }
      "500" = {
        name   = "Administracyjna"
        subnet = "172.20.20.0/24"
      }
    }
  }
  
  assert {
    condition     = length(routeros_interface_vlan.vlans) == 3
    error_message = "Should create 3 VLANs"
  }
}

# Test 4: VLAN filtering disabled
run "vlan_filtering_disabled" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = false
    vlans = {
      "101" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
  }
  
  assert {
    condition     = length(routeros_interface_bridge_vlan.vlan_filter) == 0
    error_message = "No VLAN filtering should be configured when disabled"
  }
}
