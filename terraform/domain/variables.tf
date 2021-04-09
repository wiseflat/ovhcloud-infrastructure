variable "domains" {
  description = "Domains"
  type = list(object({
    zone      = string
    subdomain = string
    target    = string
    fieldtype = string
    ttl       = number
  }))
  default = []
}
