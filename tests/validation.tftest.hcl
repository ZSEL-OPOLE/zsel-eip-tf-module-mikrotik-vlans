# =============================================================================
# MikroTik VLAN Module - Validation Tests
# =============================================================================
# Tests input validation, error handling, and edge cases

# Mock provider configuration for testing without real RouterOS device
mock_provider "routeros" {}

# Test 1: Valid configuration and validation output
run "validation_output_check" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "101" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
  }
  
  assert {
    condition     = length(output.validation_errors.invalid_subnets) == 0
    error_message = "Valid CIDR should pass validation"
  }
  
  assert {
    condition     = output.validation_errors.warning == "Configuration valid"
    error_message = "Validation warning should indicate configuration is valid"
  }
}

# Test 2: High VLAN ID (valid, RouterOS supports 1-4094)
run "high_vlan_id" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "4094" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["4094"].vlan_id == 4094
    error_message = "VLAN ID 4094 should be accepted"
  }
}

# Test 3: Low VLAN ID
run "low_vlan_id" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "1" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["1"].vlan_id == 1
    error_message = "VLAN ID 1 should be accepted"
  }
}

# Test 4: Large VLAN count (stress test)
run "large_vlan_count" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      for i in range(100, 150) : tostring(i) => {
        name   = "VLAN-${i}"
        subnet = "10.${i}.0.0/24"
      }
    }
  }
  
  assert {
    condition     = length(routeros_interface_vlan.vlans) == 50
    error_message = "Should handle 50 VLANs"
  }
}

# Test 5: Special characters in VLAN name
run "special_characters_name" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "101" = {
        name   = "Test-VLAN_123"
        subnet = "192.168.1.0/24"
      }
    }
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["101"].name == "vlan101"
    error_message = "VLAN interface name should follow standard naming"
  }
}

# Test 6: Empty trunk ports list
run "empty_trunk_ports" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "101" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
    trunk_ports = []
  }
  
  assert {
    condition     = length(routeros_interface_bridge_vlan.vlan_filter["101"].tagged) == 0
    error_message = "Empty trunk_ports should result in no tagged ports"
  }
}

# Test 7: Empty PVID map
run "empty_pvid_map" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "101" = {
        name   = "Test"
        subnet = "192.168.1.0/24"
      }
    }
    pvid_map = {}
  }
  
  assert {
    condition     = length(routeros_interface_bridge_port.port_pvid) == 0
    error_message = "Empty pvid_map should result in no port configuration"
  }
}

# Test 8: Output summaries
run "validation_output" {
  command = plan
  
  variables {
    bridge_name = "bridge1"
    vlans = {
      "101" = {
        name   = "Test1"
        subnet = "192.168.1.0/24"
      }
      "102" = {
        name   = "Test2"
        subnet = "192.168.2.0/24"
      }
    }
  }
  
  assert {
    condition     = output.vlan_summary.total_vlans == 2
    error_message = "Summary should show 2 VLANs"
  }
  
  assert {
    condition     = length(output.vlan_list) == 2
    error_message = "VLAN list should contain 2 entries"
  }
}
