# local-apigateway-infra

This is an accompanying repository to the blog post of Oramind. It will help you get moving with installing and configuring the infrastructure and application for the blog post.

- Apisix Ingress Gateway
- Keycloak
- Sample Resource Server protected with Keycloak and OpenID Connect

Format of the repository:
- [infrastructure](./infrastructure) - infrastructure
- [application](./application) - application

Steps to install
- Setup your infrastructure using the infrastructure folder. There is a makefile there that will help you get moving
- Setup your configuration based on the infrastructure by using the application folder. There is a makefile there that will help you get moving there as well.

There are `variables.tf` files inside both folders, which will help you customize the installation to your needs.
