terraform {
  required_version = ">= 1.3.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "CiscoDevNet/aci"
      version = ">=2.0.0"
    }
  }
}

module "main" {
  source = "../.."

  model = {
    apic = {
      node_policies = {
        vpc_groups = {
          groups = [{
            name     = "GROUP_1451"
            id       = 451
            switch_1 = 1451
            switch_2 = 1452
          }]
        }
      }
    }
  }
}

data "aci_rest_managed" "fabricExplicitGEp" {
  dn = "uni/fabric/protpol/expgep-GROUP_1451"

  depends_on = [module.main]
}

resource "test_assertions" "fabricExplicitGEp" {
  component = "fabricExplicitGEp"

  equal "name" {
    description = "name"
    got         = data.aci_rest_managed.fabricExplicitGEp.content.name
    want        = "GROUP_1451"
  }

  equal "id" {
    description = "id"
    got         = data.aci_rest_managed.fabricExplicitGEp.content.id
    want        = "451"
  }
}
