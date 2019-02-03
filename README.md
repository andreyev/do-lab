# do-lab

Just a simple POC of some technologies like: docker, terraform, python/flask etc.

To run, please do these steps:

Create a `terraform.tfvars` from template:
```
$ cp terraform.tfvars-template terraform.tfvars
```

Get your AWS credentials in https://console.aws.amazon.com/iam/home?#/security_credentials and put in your `terraform.tfvars`
Initialize terraform to download required plugins:
```
$ terraform init
```

Apply the current environment to AWS
```
$ terraform apply -auto-approve
```
At the end, terraform will output the `app_endpoint` of your provisioned environment.
If you lost it, run the following command to get it again and browse to running application
```
$ terraform output app_endpoint
```

Finnaly, destroy all components created
```
$ terraform destroy -auto-approve
```
