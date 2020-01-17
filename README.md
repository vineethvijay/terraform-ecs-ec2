# ECS Cluster

Build an Amazon Elastic Container Services Cluster with Terraform to deploy an test application

## Requirements

* An AWS account and an IAM user with permissions to create AWS resources

- terraform v0.11.14
- provider.aws v2.45.0

- docker 19.03.5
- aws-cli 1.16.240


## Introduction

This will create an ECS cluster, made up of a set of three nodes in an auto-scaling group across the three availability zones specified 
and deploys the application.

#### in a nutshell, it has..

* VPC with Internet Gateway, NAT Gateway, Public and Private subnets
* ECS Cluster in with EC2 type - nodes inside private subnet and attached with autoscaling group
* Service deployed in ECS with auto-scaling
* Private S3 bucket and ECS tasks allowed to write to it.
* Application Loadbalancer in-front of the application


## Usage - To run the code,

Export IAM credentials as environment variables unless you are using AWS roles
```
$ export AWS_ACCESS_KEY_ID="accesskey"
$ export AWS_SECRET_ACCESS_KEY="secretkey"
$ export AWS_DEFAULT_REGION="us-east-1"
```

Create Repository in AWS ECR (for storing the custom nginx image)

```
$ aws ecr create-repository --repository-name nginx
```

Note down the `repositoryUri` from the output


Build the docker images with two available artifact versions
```
cd nginx/
docker build . -t <repositoryUri>:tag
```

Example:
```
docker build . -t xxxxx.dkr.ecr.us-east-1.amazonaws.com/nginx:latest
```

Push the docker images to ECR (https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)

1. Login into ECR 

    Example: `eval $(aws ecr get-login --no-include-email --region us-east-1 | sed 's|https://||')`

2. Push the images built

    Example: `docker push xxxxxx.dkr.ecr.us-east-1.amazonaws.com/nginx:latest`

Note: If you have authentication issues while pushing, try login with the help of https://github.com/awslabs/amazon-ecr-credential-helper


#### If you still have troubles, you can use my public image : `vineethvijay/nginx-custom-port:latest` ;)


Change the `image` under terraform/files/nginx-task.json

```
cd terraform/
terraform init

terraform plan
terraform apply
```

Access the nginx page with the output endpoint. 
You may also check the in AWS ECS service console to see whether the tasks are in `RUNNING` state`.


