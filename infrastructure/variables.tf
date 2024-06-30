variable "kubeconfig" {
  type = map(string)
}

variable "ingress_domain" {
    type = string
    default = "k8s.orb.local"
}
