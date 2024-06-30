resource "kubectl_manifest" "apisix-keycloak-login-route" {
  yaml_body = <<YAML
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: login-apisix
  namespace: keycloak
spec:
  http:
  - name: loginhttp
    match:
      paths:
        - "/openid-connect/.well-known/openid-configuration"
        - "/openid-connect/auth/token"
    backends:
      - serviceName: keycloak-proxy
        servicePort: 80
    plugins:
    - name: proxy-rewrite
      enable: true
      config:
        regex_uri:
          - ^/openid-connect/auth/token$
          - /realms/foorealm/protocol/openid-connect/token
          - ^/openid-connect/.well-known/openid-configuration$
          - /realms/foorealm/.well-known/openid-configuration
YAML
}

resource "kubectl_manifest" "echoserver1_route" {
  yaml_body = <<YAML
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: echoservice1
  namespace: ${kubernetes_namespace_v1.echonamespace1.metadata.0.name}
spec:
  http:
  - name: echo1
    match:
      paths:
        - "/echo1"
    backends:
      - serviceName: echoserver1-service
        servicePort: 80
YAML
}


resource "kubectl_manifest" "echoserver1_authenticated_route" {
  yaml_body = <<YAML
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: echoserver-authenticated
  namespace: ${kubernetes_namespace_v1.echonamespace1.metadata.0.name}
spec:
  http:
  - name: echohttpauthenticated
    match:
      paths:
      - "/protected*"
    backends:
    - serviceName: echoserver1-service
      servicePort: 80
    plugins:
      - name: "openid-connect"
        enable: true
        config:
          client_id: "${var.client_configs.apisix.client_id}"
          client_secret: "${var.client_configs.apisix.client_secret}"
          discovery: "http://keycloak-proxy.keycloak.svc.cluster.local/realms/foorealm/.well-known/openid-configuration"
          token_endpoint: "http://keycloak-proxy.keycloak.svc.cluster.local/realms/foorealm/protocol/openid-connect/token"
          introspection_endpoint: "http://keycloak-proxy.keycloak.svc.cluster.local/realms/foorealm/protocol/openid-connect/token/introspect"
          bearer_only: true
          realm: "apisixrealm"
YAML
}
