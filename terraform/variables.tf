
variable "db_list" {
  type = list(object({
    key     = string
    engine  = string
    version = number
  }))
  default = [
    {
      key     = "store_db"
      engine  = "postgres"
      version = 13
    },
    {
      key     = "admin_db"
      engine  = "postgres"
      version = 13
    }
  ]
}


variable "services_list" {
  type = list(object({
    key    = string
    port   = number
    memory = number
    cpu    = number
    image  = optional(string)
    db = optional(list(object({
      type   = string
      prefix = optional(string)
    })))
    entrypoint = optional(string)
  }))
  default = [
    {
      key    = "store-api"
      port   = 3000
      memory = 2048
      cpu    = 256
      db = [
        {
          type   = "store_db"
          prefix = ""
        }
      ]
    },
    {
      key    = "store-front"
      port   = 3000
      memory = 512
      cpu    = 256
    },
    {
      key    = "admin-front"
      port   = 4000
      memory = 512
      cpu    = 256
    },
    {
      key    = "admin-api"
      port   = 3001
      memory = 2048
      cpu    = 256
      db = [
        {
          type   = "store_db"
          prefix = "STORE_"
        },
        {
          type   = "admin_db"
          prefix = ""
        }
      ],
      entrypoint = "./scripts/admin-api.entrypoint.sh"
    },
    {
      key    = "peppermint"
      port   = 3001
      memory = 2048
      cpu    = 256
      image  = "ghcr.io/tzconnectberlin/peppermint:1.2"
      db = [
        {
          type   = "store_db"
          prefix = ""
        }
      ]
      entrypoint = "./scripts/peppermint.entrypoint.sh"
    },
    {
      key    = "admin-quepasa"
      port   = 3001
      memory = 2048
      cpu    = 256
      image  = "ghcr.io/tzconnectberlin/que-pasa:1.2.5"
      db = [
        {
          type   = "admin_db"
          prefix = ""
        }
      ],
      entrypoint = "./scripts/peppermint.entrypoint.sh"
    },
    {
      key    = "store-quepasa"
      port   = 3001
      memory = 2048
      cpu    = 256
      image  = "ghcr.io/tzconnectberlin/que-pasa:1.2.5"
      db = [
        {
          type   = "store_db"
          prefix = ""
        }
      ],
      entrypoint = "./scripts/store-quepasa.entrypoint.sh"
    }
  ]
}
