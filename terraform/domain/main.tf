resource "ovh_domain_zone_record" "domain" {
  for_each = {
    for pair in var.domains : "${pair.subdomain}.${pair.zone}" => pair
  }

  zone      = each.value.zone
  subdomain = each.value.subdomain
  fieldtype = each.value.fieldtype
  ttl       = each.value.ttl
  target    = each.value.target
}
