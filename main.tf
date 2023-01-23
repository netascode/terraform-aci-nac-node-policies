locals {
  user_defaults   = { "defaults" : try(var.model.defaults, {}) }
  defaults        = lookup(yamldecode(data.utils_yaml_merge.defaults.output), "defaults")
  modules         = try(var.model.modules, {})
  apic            = try(var.model.apic, {})
  access_policies = try(local.apic.access_policies, {})
  node_policies   = try(local.apic.node_policies, {})
}

module "defaults" {
  source  = "netascode/nac-defaults/null"
  version = "0.1.0"
}

data "utils_yaml_merge" "defaults" {
  input = [yamlencode(module.defaults.defaults), yamlencode(local.user_defaults)]
}

resource "null_resource" "dependencies" {
  triggers = {
    dependencies = join(",", var.dependencies)
  }
}

module "aci_firmware_group" {
  source  = "netascode/firmware-group/aci"
  version = "0.1.0"

  for_each = { for np in try(local.node_policies.update_groups, {}) : np.name => np if try(local.modules.aci_firmware_group, true) }
  name     = "${each.value.name}${local.defaults.apic.node_policies.update_groups.name_suffix}"
  node_ids = [for node in try(local.node_policies.nodes, []) : node.id if try(node.update_group, "") == each.value.name]

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_maintenance_group" {
  source  = "netascode/maintenance-group/aci"
  version = "0.1.0"

  for_each = { for np in try(local.node_policies.update_groups, {}) : np.name => np if try(local.modules.aci_maintenance_group, true) }
  name     = "${each.value.name}${local.defaults.apic.node_policies.update_groups.name_suffix}"
  node_ids = [for node in try(local.node_policies.nodes, []) : node.id if try(node.update_group, "") == each.value.name]

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_vpc_group" {
  source  = "netascode/vpc-group/aci"
  version = "0.2.0"

  count = try(local.modules.aci_vpc_group, true) == false ? 0 : 1
  mode  = try(local.node_policies.vpc_groups.mode, local.defaults.apic.node_policies.vpc_groups.mode)
  groups = [for group in try(local.node_policies.vpc_groups.groups, []) : {
    name     = try(group.name, replace("${group.id}:${group.switch_1}:${group.switch_2}", "/^(?P<id>.+):(?P<switch1_id>.+):(?P<switch2_id>.+)$/", replace(replace(replace(try(local.access_policies.vpc_group_name, local.defaults.apic.access_policies.vpc_group_name), "\\g<id>", "$id"), "\\g<switch1_id>", "$switch1_id"), "\\g<switch2_id>", "$switch2_id")))
    id       = group.id
    policy   = try(group.policy, "")
    switch_1 = group.switch_1
    switch_2 = group.switch_2
  }]

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_node_registration" {
  source  = "netascode/node-registration/aci"
  version = "0.1.0"

  for_each      = { for node in try(local.node_policies.nodes, []) : node.id => node if contains(["leaf", "spine"], node.role) && try(local.modules.aci_node_registration, true) }
  name          = each.value.name
  node_id       = each.value.id
  pod_id        = try(each.value.pod, local.defaults.apic.node_policies.nodes.pod)
  serial_number = each.value.serial_number
  type          = try(each.value.type, "unspecified")

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_inband_node_address" {
  source  = "netascode/inband-node-address/aci"
  version = "0.1.2"

  for_each       = { for node in try(local.node_policies.nodes, []) : node.id => node if(try(node.inb_address, null) != null || try(node.inb_v6_address, null) != null) && try(local.modules.aci_inband_node_address, true) }
  node_id        = each.value.id
  pod_id         = try(each.value.pod, local.defaults.apic.node_policies.nodes.pod)
  ip             = try(each.value.inb_address, "")
  gateway        = try(each.value.inb_gateway, "")
  v6_ip          = try(each.value.inb_v6_address, "")
  v6_gateway     = try(each.value.inb_v6_gateway, "")
  endpoint_group = try(local.node_policies.inb_endpoint_group, local.defaults.apic.node_policies.inb_endpoint_group)

  depends_on = [
    null_resource.dependencies,
  ]
}

module "aci_oob_node_address" {
  source  = "netascode/oob-node-address/aci"
  version = "0.1.2"

  for_each       = { for node in try(local.node_policies.nodes, []) : node.id => node if(try(node.oob_address, null) != null || try(node.oob_v6_address, null) != null) && try(local.modules.aci_oob_node_address, true) }
  node_id        = each.value.id
  pod_id         = try(each.value.pod, local.defaults.apic.node_policies.nodes.pod)
  ip             = try(each.value.oob_address, "")
  gateway        = try(each.value.oob_gateway, "")
  v6_ip          = try(each.value.oob_v6_address, "")
  v6_gateway     = try(each.value.oob_v6_gateway, "")
  endpoint_group = try(local.node_policies.oob_endpoint_group, local.defaults.apic.node_policies.oob_endpoint_group)

  depends_on = [
    null_resource.dependencies,
  ]
}

resource "null_resource" "critical_resources_done" {
  triggers = {
  }
}
