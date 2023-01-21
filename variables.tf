variable "model" {
  description = "Model data."
  type        = any
}

variable "dependencies" {
  description = "This variable can be used to express explicit dependencies between modules."
  type        = list(string)
  default     = []
}
