resource "kubernetes_namespace_v1" "echonamespace1" {
metadata {
    name = "echonamespace1"
  }
}

resource "kubernetes_deployment_v1" "echodeployment1" {
  metadata {
    name = "echodeployment1"
    labels = {
      app = "echo1"
    }
    namespace = kubernetes_namespace_v1.echonamespace1.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "echo1"
      }
    }
    template {
      metadata {
        labels = {
          app = "echo1"
        }
      }
      spec {
        container {
          image = "ealen/echo-server"
          name = "application"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "echoserver1" {
  metadata {
    name = "echoserver1-service"
    namespace = kubernetes_deployment_v1.echodeployment1.metadata.0.namespace
  }

  spec {
    selector = {
      app = "echo1"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

