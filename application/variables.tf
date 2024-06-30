variable "kubeconfig" {
  type = map(string)
}

variable "ingress_domain" {
    type = string
    default = "k8s.orb.local"
}


variable "client_configs" {
  type = object({
      apisix = object({
      client_id = string
      client_secret = string
      })
  })
  default = {
    apisix = {
      client_id = "apisix"
      client_secret = "gC2Z0cUEqpVJ1ryU44lkgXCtB21Rgpi7"
    }
  }
}
