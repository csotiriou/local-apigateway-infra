apisix_dep_update:
	cd "config/apisix/apisix-helm-chart-master/charts/apisix" && helm dependency update

terraform_init:
	terraform init

terraform_plan:
	terraform plan --var-file=config/deploy.tfvars

terraform_apply: apisix_dep_update
	terraform apply --var-file=config/deploy.tfvars --auto-approve

terraform_apply_no_dep_update:
	terraform apply --var-file=config/deploy.tfvars --auto-approve

terraform_destroy:
	terraform destroy --var-file=config/deploy.tfvars

terraform_reset:
	rm -rf .terraform
	rm -rf terraform.tfstate*
	rm -rf .terraform.lock.hcl
