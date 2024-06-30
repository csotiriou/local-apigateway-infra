terraform {
  required_providers {
    kubectl = {
      source = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig.path
    config_context = var.kubeconfig.default_context
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig.path
  config_context = var.kubeconfig.default_context
}

provider "kubectl" {
  config_path =  var.kubeconfig.path
  config_context = var.kubeconfig.default_context
}


