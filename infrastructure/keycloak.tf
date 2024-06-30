# first create the namespace for keycloak
resource "kubernetes_namespace_v1" "keycloak_namespace" {
  metadata {
    name = "keycloak"
  }
}

resource "null_resource" "install_keycloak_operator_script" {
  depends_on = [kubernetes_namespace_v1.keycloak_namespace]

  provisioner "local-exec" {
    when    = create
    command = <<COMMAND
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/kubernetes.yml -nkeycloak
    COMMAND
  }

  provisioner "local-exec" {
    when = destroy
    command = <<COMMAND
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/kubernetes.yml -nkeycloak
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/24.0.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
COMMAND
  }

}


resource "kubernetes_secret_v1" "keycloak_db_secret" {
  depends_on = [null_resource.install_keycloak_operator_script]
  type = "Opaque"
  metadata {
    name = "keycloak-db-secret"
    namespace = kubernetes_namespace_v1.keycloak_namespace.metadata.0.name
  }
  data = {
    username = "keycloak"
    password = "keycloak"
  }
}

resource "kubernetes_secret_v1" "keycloak_certificate" {
  metadata {
    name = "keycloak-certificate"
    namespace = kubernetes_namespace_v1.keycloak_namespace.metadata.0.name
  }
  data = {
    "tls.crt" = file("./config/keycloak/certificate.pem")
    "tls.key" = file("./config/keycloak/key.pem")
  }
  type = "kubernetes.io/tls"
}

resource "helm_release" "keycloak_postgres" {
  depends_on = [
    null_resource.install_keycloak_operator_script,
    kubernetes_secret_v1.keycloak_certificate
  ]
  chart = "postgresql"
  name  = "keycloak-postgres"
  namespace = kubernetes_namespace_v1.keycloak_namespace.metadata.0.name
  repository = "https://charts.bitnami.com/bitnami"
  values = [file("./config/keycloak/keycloak-postgres.yaml")]
}

resource "kubectl_manifest" "keycloak_installation" {
  depends_on = [helm_release.keycloak_postgres, null_resource.install_keycloak_operator_script]
  yaml_body = <<YAML
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: main-keycloak
  namespace: ${kubernetes_namespace_v1.keycloak_namespace.metadata.0.name}
spec:
  instances: 1
  http:
    httpEnabled: true
    httpPort: 8080
  hostname:
    strict: false
    strictBackchannel: false
  ingress:
    enabled: false
  db:
    vendor: postgres
    host: keycloak-postgres-postgresql
    usernameSecret:
      name: ${kubernetes_secret_v1.keycloak_db_secret.metadata.0.name}
      key: username
    passwordSecret:
      name: ${kubernetes_secret_v1.keycloak_db_secret.metadata.0.name}
      key: password
  log:
    logLevel: TRACE
YAML
}

resource "helm_release" "keycloak_proxy" {
  depends_on = [kubectl_manifest.keycloak_installation]
  chart = "./config/keycloakproxy/helm"
  name  = "keycloakproxy"
  namespace = kubernetes_namespace_v1.keycloak_namespace.metadata.0.name
  timeout = 20
}

resource "kubernetes_ingress_v1" "keycloak_ingress" {
  depends_on = [kubectl_manifest.keycloak_installation]
  metadata {
    name = "keycloak-ingress"
    namespace = kubernetes_namespace_v1.keycloak_namespace.metadata[0].name
  }
  spec {
    ingress_class_name = "apisix"
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "keycloak-proxy"
              port {
                number = 80
              }
            }
          }
        }
      }
      host = "keycloak.${var.ingress_domain}"
    }
  }
}

data "kubernetes_secret_v1" "initial_keycloak_credentials" {
  metadata {
    name = "main-keycloak-initial-admin"
    namespace = kubernetes_namespace_v1.keycloak_namespace.metadata.0.name
  }
}

output "keycloak_credentials" {
  value = nonsensitive(data.kubernetes_secret_v1.initial_keycloak_credentials.data)
}
