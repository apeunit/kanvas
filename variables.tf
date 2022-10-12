variable "services_list" {
  type = list(object({
    key    = string
    port   = number
    memory = number
    cpu    = number
  }))
  default = [
    {
      key    = "first"
      port   = 3000
      memory = 512
      cpu    = 256
    },
    {
      key    = "second"
      port   = 3000
      memory = 512
      cpu    = 256
    },
    {
      key    = "third"
      port   = 3000
      memory = 512
      cpu    = 256
    },
    {
      key    = "fourth"
      port   = 3000
      memory = 512
      cpu    = 256
    }
  ]
}
