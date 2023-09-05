## Prerequisites:
Make sure the following tools are installed on your system:
- Terraform
- Docker

## Configure:
Provision the values specified in values.tf file using one of the standard terraform methods:
- Run ```terraform apply``` and provide values at the prompt
- Export values via the shell using TF_VALUES_\<varName>
- Create a values file and run ```terraform apply -var-file=\<valuesPath>```

## How to run:
- terraform init
- terraform apply