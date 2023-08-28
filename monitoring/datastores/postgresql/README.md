## Prerequisites:
- terraform
- docker

## Configure:
Provide the values specified in values.tf file using the following methods:
- input them after running tf apply
- export them using TF_VALUES_\<varName>
- provide values file and run terraform apply -var-file=\<valuesPath>

## How to run:
- terraform init
- terraform apply