# =============================================================================
# MikroTik VLAN Module - Integration Tests
# =============================================================================
# Tests complex scenarios with trunk ports, PVID, and VLAN filtering

# Mock provider configuration for testing without real RouterOS device
mock_provider "routeros" {}

# Test 1: Full VLAN configuration with bridge VLAN filtering
run "full_vlan_config" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "101" = {
        name    = "Dydaktyczna-P0"
        subnet  = "192.168.1.0/24"
        comment = "Sieć dydaktyczna parter"
      }
      "208" = {
        name    = "Pracownia-208"
        subnet  = "10.208.0.0/16"
        comment = "Pracownia 208"
      }
      "500" = {
        name    = "Administracyjna"
        subnet  = "172.20.20.0/24"
        comment = "Sieć administracyjna"
      }
    }
    trunk_ports = ["ether1", "ether2", "sfp-sfpplus1"]
    pvid_map = {
      "ether10" = 101
      "ether15" = 208
      "ether20" = 500
    }
  }
  
  assert {
    condition     = length(routeros_interface_vlan.vlans) == 3
    error_message = "Should create 3 VLANs"
  }
  
  assert {
    condition     = length(routeros_interface_bridge_vlan.vlan_filter) == 3
    error_message = "Should create 3 VLAN filter entries"
  }
  
  assert {
    condition     = length(routeros_interface_bridge_port.port_pvid) == 3
    error_message = "Should configure 3 access ports with PVID"
  }
}

# Test 2: Trunk ports configuration
run "trunk_ports" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "10" = {
        name   = "K3s-Control-Plane"
        subnet = "10.10.10.0/24"
      }
      "20" = {
        name   = "K3s-Workers"
        subnet = "10.10.20.0/24"
      }
    }
    trunk_ports = ["qsfp28-1-1", "qsfp28-1-2", "sfp28-1", "sfp28-2"]
  }
  
  # Verify trunk ports are tagged for VLANs
  assert {
    condition     = contains(routeros_interface_bridge_vlan.vlan_filter["10"].tagged, "qsfp28-1-1")
    error_message = "Trunk port qsfp28-1-1 should be tagged for VLAN 10"
  }
  
  assert {
    condition     = contains(routeros_interface_bridge_vlan.vlan_filter["20"].tagged, "sfp28-1")
    error_message = "Trunk port sfp28-1 should be tagged for VLAN 20"
  }
}

# Test 3: PVID assignment for access ports
run "pvid_assignment" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "300" = {
        name   = "WiFi-P0"
        subnet = "10.100.1.0/24"
      }
      "301" = {
        name   = "WiFi-P1"
        subnet = "10.100.2.0/24"
      }
    }
    pvid_map = {
      "ether5"  = 300
      "ether6"  = 300
      "ether10" = 301
      "ether11" = 301
    }
  }
  
  # Verify PVID assignments
  assert {
    condition     = routeros_interface_bridge_port.port_pvid["ether5"].pvid == 300
    error_message = "Port ether5 should have PVID 300"
  }
  
  assert {
    condition     = routeros_interface_bridge_port.port_pvid["ether11"].pvid == 301
    error_message = "Port ether11 should have PVID 301"
  }
  
  # Verify access ports are untagged
  assert {
    condition     = contains(routeros_interface_bridge_vlan.vlan_filter["300"].untagged, "ether5")
    error_message = "Access port ether5 should be untagged for VLAN 300"
  }
}

# Test 4: Large deployment (31 VLANs for BCU project)
run "large_deployment" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      # Dydaktyczne
      "101" = { name = "Dydaktyczna-P0", subnet = "192.168.1.0/24" }
      "102" = { name = "Dydaktyczna-P1", subnet = "192.168.2.0/24" }
      "103" = { name = "Dydaktyczna-P2", subnet = "192.168.3.0/24" }
      "104" = { name = "Dydaktyczna-P3", subnet = "192.168.4.0/24" }
      # Kubernetes
      "10"  = { name = "K3s-Control", subnet = "10.10.10.0/24" }
      "20"  = { name = "K3s-Workers", subnet = "10.10.20.0/24" }
      "30"  = { name = "K3s-LoadBalancer", subnet = "10.10.30.0/24" }
      "40"  = { name = "K3s-Storage", subnet = "10.10.40.0/24" }
      "50"  = { name = "K3s-VPN", subnet = "10.10.50.0/24" }
      # WiFi
      "300" = { name = "WiFi-P0", subnet = "10.100.1.0/24" }
      "301" = { name = "WiFi-P1", subnet = "10.100.2.0/24" }
      # Infrastructure
      "110" = { name = "Telewizory", subnet = "192.168.10.0/24" }
      "500" = { name = "Administracyjna", subnet = "172.20.20.0/24" }
      "501" = { name = "CCTV", subnet = "172.21.1.0/24" }
      "600" = { name = "Management", subnet = "192.168.255.0/28" }
      # Pracownie (sample)
      "208" = { name = "Pracownia-208", subnet = "10.208.0.0/16" }
      "210" = { name = "Pracownia-210", subnet = "10.210.0.0/16" }
      "220" = { name = "Pracownia-220", subnet = "10.220.0.0/16" }
    }
    trunk_ports = ["qsfp28-1-1", "qsfp28-1-2", "sfp28-1", "sfp28-2"]
  }
  
  assert {
    condition     = length(routeros_interface_vlan.vlans) == 18
    error_message = "Should create 18 VLANs"
  }
  
  assert {
    condition     = length(routeros_ip_address.vlan_gateways) == 18
    error_message = "Should create 18 gateway IPs"
  }
}

# Test 5: Bridge validation
run "bridge_validation" {
  command = plan
  
  variables {
    bridge_name           = "bridge-main"
    enable_vlan_filtering = true
    vlans = {
      "100" = {
        name   = "Test-VLAN"
        subnet = "10.0.100.0/24"
      }
    }
  }
  
  assert {
    condition     = routeros_interface_vlan.vlans["100"].interface == "bridge-main"
    error_message = "VLAN should use bridge-main"
  }
  
  assert {
    condition     = routeros_interface_bridge_vlan.vlan_filter["100"].bridge == "bridge-main"
    error_message = "VLAN filter should use bridge-main"
  }
}

# Test 6: Untagged ports for bridge
run "bridge_untagged" {
  command = plan
  
  variables {
    bridge_name           = "bridge1"
    enable_vlan_filtering = true
    vlans = {
      "500" = {
        name   = "Admin"
        subnet = "172.20.20.0/24"
      }
    }
    trunk_ports = ["ether1"]
    pvid_map = {
      "ether5" = 500
    }
  }
  
  # Access port should be in untagged list
  assert {
    condition     = contains(routeros_interface_bridge_vlan.vlan_filter["500"].untagged, "ether5")
    error_message = "Access port ether5 should be in untagged list for VLAN 500"
  }
}
