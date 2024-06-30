
resource "kubernetes_namespace_v1" "apisix_namespace" {
    metadata {
        name = "ingress-apisix"
    }
}


resource "kubernetes_config_map_v1" "custom_response_plugin_configmap" {
  metadata {
    name = "custom-response-config"
    namespace = kubernetes_namespace_v1.apisix_namespace.metadata.0.name
  }
  data = {
    "custom-response.lua" = file("${path.module}/config/apisix/custom-response.lua")
  }
}


resource "kubernetes_config_map_v1" "add-clientid-header_configmap" {
  metadata {
    name = "add-clientid-header-config"
    namespace = kubernetes_namespace_v1.apisix_namespace.metadata.0.name
  }
  data = {
    "add-clientid-header.lua" = file("${path.module}/config/apisix/add-clientid-header.lua")
  }
}

resource "helm_release" "apisix_helm" {
  depends_on = [
    kubernetes_config_map_v1.custom_response_plugin_configmap,
    kubernetes_config_map_v1.add-clientid-header_configmap
  ]
  chart = "${path.module}/config/apisix/apisix-helm-chart-master/charts/apisix"
  name  = "apisix"
  repository = "https://charts.apiseven.com"
  namespace = kubernetes_namespace_v1.apisix_namespace.metadata.0.name
  dependency_update = true
  force_update = true
  values = [
    file("config/apisix/apisix-values.yaml"),
  ]
}



# resource "helm_release" "apisix_dashboard_helm" {
#   depends_on = [helm_release.apisix_helm]
#   chart = "./config/apisix/apisix-helm-chart-master/charts/apisix-dashboard"
#   name  = "apisix-dashboard"
#   repository = "https://charts.apiseven.com"
#   namespace = kubernetes_namespace_v1.apisix_namespace.metadata.0.name
# }


# resource "kubernetes_ingress_v1" "dashboard_ingress" {
#   depends_on = [helm_release.apisix_dashboard_helm]
#   metadata {
#     namespace = kubernetes_namespace_v1.apisix_namespace.metadata.0.name
#     name = "dashboard-ingress"
#   }
#   spec {
#     ingress_class_name = "apisix"
#     rule {
#       host = "dashboard.${var.ingress_domain}"
#       http {
#         path {
#           path = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "apisix-dashboard"
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
