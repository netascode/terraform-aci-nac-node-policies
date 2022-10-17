locals {
  defaults        = lookup(var.model, "defaults", {})
  modules         = lookup(var.model, "modules", {})
  apic            = lookup(var.model, "apic", {})
  access_policies = lookup(local.apic, "access_policies", {})
  node_policies   = lookup(local.apic, "node_policies", {})
}

module "aci_firmware_group" {
  source  = "netascode/firmware-group/aci"
  version = "0.1.0"

  for_each = { for np in lookup(local.node_policies, "update_groups", {}) : np.name => np if lookup(local.modules, "aci_firmware_group", true) }
  name     = "${each.value.name}${local.defaults.apic.node_policies.update_groups.name_suffix}"
  node_ids = [for node in lookup(local.node_policies, "nodes", []) : node.id if lookup(node, "update_group", "") == each.value.name]
}

module "aci_maintenance_group" {
  source  = "netascode/maintenance-group/aci"
  version = "0.1.0"

  for_each = { for np in lookup(local.node_policies, "update_groups", {}) : np.name => np if lookup(local.modules, "aci_maintenance_group", true) }
  name     = "${each.value.name}${local.defaults.apic.node_policies.update_groups.name_suffix}"
  node_ids = [for node in lookup(local.node_policies, "nodes", []) : node.id if lookup(node, "update_group", "") == each.value.name]
}

module "aci_vpc_group" {
  source  = "netascode/vpc-group/aci"
  version = "0.2.0"

  count = lookup(local.modules, "aci_vpc_group", true) == false ? 0 : 1
  mode  = lookup(lookup(local.node_policies, "vpc_groups", {}), "mode", local.defaults.apic.node_policies.vpc_groups.mode)
  groups = [for group in lookup(lookup(local.node_policies, "vpc_groups", {}), "groups", []) : {
    name     = replace("${group.id}:${group.switch_1}:${group.switch_2}", "/^(?P<id>.+):(?P<switch1_id>.+):(?P<switch2_id>.+)$/", replace(replace(replace(lookup(local.access_policies, "vpc_group_name", local.defaults.apic.access_policies.vpc_group_name), "\\g<id>", "$id"), "\\g<switch1_id>", "$switch1_id"), "\\g<switch2_id>", "$switch2_id"))
    id       = group.id
    policy   = lookup(group, "policy", "")
    switch_1 = group.switch_1
    switch_2 = group.switch_2
  }]
}

module "aci_node_registration" {
  source  = "netascode/node-registration/aci"
  version = "0.1.0"

  for_each      = { for node in lookup(local.node_policies, "nodes", []) : node.id => node if contains(["leaf", "spine"], node.role) && lookup(local.modules, "aci_node_registration", true) }
  name          = each.value.name
  node_id       = each.value.id
  pod_id        = lookup(each.value, "pod", local.defaults.apic.node_policies.nodes.pod)
  serial_number = each.value.serial_number
  type          = lookup(each.value, "type", "unspecified")
}

module "aci_inband_node_address" {
  source  = "netascode/inband-node-address/aci"
  version = "0.1.2"

  for_each       = { for node in lookup(local.node_policies, "nodes", []) : node.id => node if(lookup(node, "inb_address", null) != null || lookup(node, "inb_v6_address", null) != null) && lookup(local.modules, "aci_inband_node_address", true) }
  node_id        = each.value.id
  pod_id         = lookup(each.value, "pod", local.defaults.apic.node_policies.nodes.pod)
  ip             = lookup(each.value, "inb_address", "")
  gateway        = lookup(each.value, "inb_gateway", "")
  v6_ip          = lookup(each.value, "inb_v6_address", "")
  v6_gateway     = lookup(each.value, "inb_v6_gateway", "")
  endpoint_group = lookup(local.node_policies, "inb_endpoint_group", local.defaults.apic.node_policies.inb_endpoint_group)
}

module "aci_oob_node_address" {
  source  = "netascode/oob-node-address/aci"
  version = "0.1.2"

  for_each       = { for node in lookup(local.node_policies, "nodes", []) : node.id => node if(lookup(node, "oob_address", null) != null || lookup(node, "oob_v6_address", null) != null) && lookup(local.modules, "aci_oob_node_address", true) }
  node_id        = each.value.id
  pod_id         = lookup(each.value, "pod", local.defaults.apic.node_policies.nodes.pod)
  ip             = lookup(each.value, "oob_address", "")
  gateway        = lookup(each.value, "oob_gateway", "")
  v6_ip          = lookup(each.value, "oob_v6_address", "")
  v6_gateway     = lookup(each.value, "oob_v6_gateway", "")
  endpoint_group = lookup(local.node_policies, "oob_endpoint_group", local.defaults.apic.node_policies.oob_endpoint_group)
}
