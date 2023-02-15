## 0.4.1 (unreleased)

- Allow pod ID 0 for standalone APICs

## 0.4.0

- Include default values in module
- BREAKING CHANGE: `depends_on` can no longer be used to express explicit dependencies between NaC modules. The variable `dependencies` and the output `critical_resources_done` can be used instead, to ensure a certain order of operations.

## 0.3.2

- Add option to configure individual vPC group name

## 0.3.1

- Harmonize module flags

## 0.3.0

- Pin module dependencies

## 0.2.1

- Fix unintended deletion of inband EPG when inband node address is removed
- Fix unintended deletion of out-of-band EPG when out-of-band node address is removed

## 0.2.0

- Use Terraform 1.3 compatible modules

## 0.1.1

- Update readme and add link to Nexus-as-Code project documentation

## 0.1.0

- Initial release
