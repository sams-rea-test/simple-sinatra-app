REA Systems Engineer practical task
===================================

Hi there! Thanks for reviewing my practical tests. I hope it's at least a little interesting and not a complete flop.
I hope it's not too obvious that ruby apps aren't my strong point when assessing.


## Assumptions I've made

Hi there! Just to be super clear, here are some of the assumptions that I've made with what is acceptable for our 
application's infrastructure:

- Developing and deploying using Docker is acceptable
- Using the official ruby docker images - based on Debian Jessie - is acceptable (although as noted in the `Dockerfile`,
   converting to Alpine or Centos is achievable as well, and if RHEL is more your taste, that could be done, too.) 
- Deploying the application onto AWS and EC2 Container Services (ECS) is acceptable
- Using CloudFormation to provision the infrastructure is acceptable (but unofficial AWS management tools like 
   Terraform could also be used instead).


## Explaining the solution

I decided to use Docker as a solution to deliver the application, because it is a great tool to use both in development
environments, and to package and provide artifacts for runtime on the server.  Among other reasons, it ensures that 
developers are using an environment configured closely to what is served on production, and does allow 
environment-agnostic artifacts to be built and promoted from development through to production.
 
I've provided a docker-compose solution for use in development (although noted below that development teams might 
struggle without a reload tool), as well as a series of CloudFormation scripts that will boot the environment on Amazon
EC2 Container Services (ECS).

Following on from AWS' described "best practices", my CloudFormation templates are split into 4 key areas, to try and 
maintain a separation of responsibilities where possible. The areas, which are described in further detail below are:
 
 - Isolation & networking
 - Compute resources
 - Application artifact storage
 - Application runtime


## Requirements

In order to work on this application, it is assumed that you would have the following installed and configured on your 
local machine:

- Docker ([one of the linux distributions of Docker engine](https://docs.docker.com/engine/installation/) on linux, 
   [Docker for Mac](https://docs.docker.com/docker-for-mac/) on a Mac or 
   [Docker for Windows](https://docs.docker.com/docker-for-windows/install/) on a Windows PC), including 
   [Docker Compose](https://docs.docker.com/compose/).

If you want to deploy this app, you'll need to have the following:

- [AWS Command-line tools](https://aws.amazon.com/cli/) 
- AWS access key + secret configured (either as environment variables, AWS credentials file, or [another method that is 
   supported by the client](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)) with access 
   to CloudFormation and IAM APIs. 


## Developing

For example purposes, this application is very basic. But, in a real-world case, we'd have actual developers building 
upon it.

So, if you want to develop upon this (i.e. add real routes and functionality), you would need to do the following:

1. Check out the repository
2. Build the application:

       docker-compose build --pull app

3. Start the application:
    
       docker-compose up

4. Start working the codes. 

Note: I couldn't work out how to get [rerun](http://www.sinatrarb.com/faq.html#reloading) working for development only
but this (or something similar) would be a logical step for having productive development. 
For now, any changes to the application's files would need a `docker-compose restart`.


## Deployment

To keep the VPC and associated networking infrastructure only loosely coupled to the actual machines, the CloudFormation
scripts are split up into a series of files, which need to be created in sequence:

- **01-vpc-networking.yaml**: A VPC configured with a subnet in each of up-to 3 availability zones, an internet gateway 
   and associated routing. Note: Default values are appropriate for ap-southeast-2 (AWS Sydney), but the script should
   work for any region.
   
- **02-ecs.yaml**: An ECS cluster and EC2 launch configuration and auto-scaling group to be able to provision containers
   on to.
   
- **03-ecr.yaml**: An ECR repository ("ATM machine") and IAM policy to use to push docker containers to for deploying 
   on to the ECS cluster.

- **04-ecr-services.yaml**: Finally, adds a load balancer and the ECS services to run the container on AWS ECS.

A stack-in-stack CloudFormation script is also provided (**00-cloudformation-stackinstack.yaml**) which accepts all the 
defaults mentioned below, as a way of deploying the infrastructure quickly.


### Deploying using the stack-in-stack template

1. Create a CloudFormation stack for the `00-cloudformation-stackinstack.yaml` template. 

   Accept the default values for the *URL parameters, select a SSH keypair, and set **IsContainerReadyToDeploy**
   to `no`.

   Note: If you don't want to upload my templates to your own S3, you can deploy it to CloudFormation using the 
   following URL: [https://s3-ap-southeast-2.amazonaws.com/rea-cruitment-cfscripts/00-cloudformation-stackinstack.yaml](https://s3-ap-southeast-2.amazonaws.com/rea-cruitment-cfscripts/00-cloudformation-stackinstack.yaml)

2. Once the mega-stack and it's (initial) three child stacks have created, view the outputs and note the 
   `DockerPushAddress` value.  

3. Build the docker image, like so:

   (Assuming you are inside the directory containing this file)

       docker build -t [repository URI from step 2] .
       
4. Log in to ECR using the login command below:

       eval $(aws ecr get-login --region ap-southeast-2)

5. Push the docker image to ECR, like so:

       docker push [repository URI from step 2]

6. Update the mega-stack's parameters, and set **IsContainerReadyToDeploy** to `yes`. 

7. Wait for the stack to create, and then you can access the application at the URL provided in the `PublicURL` stack 
   output.


### Deploying components individually 
The process to set up the infrastructure from start to finish would work as follows:

1. Create a CloudFormation stack for the `01-vpc-networking.yaml` template. For an express experience, operating in 
   3x AWS Sydney availability zones, accept all of the defaults parameters. Name the stack **sams-rea-test-01**. 
   Wait for AWS to provision the VPC stack's resources.
   
   Complete parameter definitions:
     - `VpcCidr`: A CIDR annotation defining the boundaries of the AWS VPC's internal IP addresses. Default: 10.0.0.0/16
     - `SubnetCidr1`: A CIDR annotation defining the boundaries of AZ 1's internal IP addresses. Default: 10.0.0.0/24
     - `SubnetCidr2`: A CIDR annotation defining the boundaries of AZ 2's internal IP addresses. Default: 10.0.1.0/24
     - `SubnetCidr3`: A CIDR annotation defining the boundaries of AZ 3's internal IP addresses. Default: 10.0.2.0/24
     - `VpcAvailabilityZones`: A comma-separated list of the availability zones to operate the VPC across. 
       Default: all three AWS Sydney AZs ("ap-southeast-2c,ap-southeast-2b,ap-southeast-2a")
    
2. Create a CloudFormation stack for the `02-ecs.yaml` template.  Name the stack **sams-rea-test-02**. Moving quickly 
   through, the parameters should be something like this:
   
     - `VPCStackName`: sams-rea-test-01
     - `EcsInstanceType`: use any standard EC2 instance type, or accept the default
     - `KeyName`: if you want to allow SSH, select an EC2 key pair. If not, leave blank
     - `AsgMaxSize`: this sets both the desired and maximum EC2 instances to launch for our ECS cluster. For demo 
       purposes you probably want to leave it at 1. But feel free to play.
     - `ManagementIngressCidrIp`: important that this is set to a sane value, otherwise the EC2 machines end up with 
       open SSH access. 
     - Remaining parameters can be left with their default values
     
   Complete parameter definitions:
     - `VPCStackName`: The name of the CloudFormation stack holding the VPC and networking resources 
     - `EcsAmiId`: The AMI to use to create EC2 instances for the ECS cluster. Default: ami-fbe9eb98 (AWS' ECS 
       optimised image)
     - `EcsInstanceType`: The type of EC2 instances to launch. Default: t2.small
     - `KeyName`: An EC2 key pair (aka SSH public keys) to provision on our EC2 machines. Default: Does not provision keys
     - `AsgMaxSize`: The number of instances to launch when the stack is created. Default: 1 
     - `ManagementIngressCidrIp`: A CIDR annotation of what IP addresses can access EC2 instances over SSH. 
       Default: none (127.0.0.1/32)
     - `EbsVolumeSize`: The size of the EBS disks to provision for each EC2 instance, in GB. Default: 20GB
     - `EbsVolumeType`: The type of EBS disks to provision. Default: gp2 (AWS' key for SSD disks)
     - `EbsDeviceName`: The device name to map the EBS volume to. Default: /dev/sda1
     
3. Create a CloudFormation stack for the `03-ecr.yaml` template. Name the stack **sams-rea-test-03**. The parameters can 
   be left as their default values without issue.
   
   Before moving on, copy the repository's push commands, which can be found inside the console under 
   EC2 Container Services - Repositories - (Select the new repository) - View Push Commands.
   
   Complete parameter definitions:
     - `RepositoryName`: The name to give the repository. Default: none (CloudFormation will assign a random name)
     - `UserArn`: An ARN of an existing IAM user to grant docker push and pull access to the repository, if required.
       Default: none

4. Build the docker image, like so:

   (Assuming you are inside the directory containing this file)

       docker build -t [repository URI from step 3]:latest .
       
5. Log in to ECR using the login command provided in step #3, like so:

       eval $([login command from step 3])

6. Push the docker image to ECR, like so:

       docker push [repository URI from step 3]:latest

7. Create the final CloudFormation stack for the `04-ecr-services.yaml` template. Name the stack **sams-rea-test-04**. 
   Parameters should be similar to this:
    
     - `VPCStackName`: sams-rea-test-01 
     - `ECSStackName`: sams-rea-test-02
     - `ECRStackName`: sams-rea-test-03
     - `DesiredContainerCount`: left as default
     
   Complete parameter definitions:
     - `VPCStackName`: The name of the CloudFormation stack holding the VPC and networking resources 
     - `ECSStackName`: The name of the CloudFormation stack holding the ECS and compute resources
     - `ECRStackName`: The name of the CloudFormation stack holding the ECR (application) resources 
     - `DesiredContainerCount`: The number of container services to launch. It is recommended that this be a similar 
       value to the EC2 instaces created. Default: 1  


## Future thoughts and enhancements

- For the app to truly thrive in a production environment, you wouldn't normally run rackup as your front-facing, 
  production webserving daemon. Instead, you would normally place a dedicated web server in front, such as nginx, and 
  possibly swap rackup for a different server daemon as well. 
- No consideration has been given for DNS (you would probably use Route53 to do this), or for "SSL" (TLS) - as the brief 
  stated accessing over port 80, although every site should be accessed over TLS. 
- While the EC2 nodes do exist on an auto-scaling group, no automatic scaling rules have been implemented. Neither have 
  any application rules for when ECS should scale the containers.
- SSH is currently open to the EC2 machines, although this would most likely be something you would disable all together
  (and treat the nodes instead like a 'managed service' similar to an RDS instance), or if absolutely required, you 
  would move to be accessible only behind a VPN connection, using VPC VPNs, or having a separate bastion jumpbox 
  sitting alone in the public subnets.
- Finally, normally you would not expect that someone would actually manually build and push docker images. This would 
  be the task of your CI/CD service. It seemed beyond the scope of this to go into selecting, configuring and using a 
  CI, but for real workloads it's what I would be using.
- Logs for the EC2 instances and the container services are going off into the ether, and should probably be captured
  somewhere centrally for future troubleshooting and analysis. Recommended that these are either directly logged to 
  CloudWatch, or using syslog, or into an ELK setup.  


## Things I learnt

- Don't follow the template examples for naming your EBS volumes! They suggest `/dev/sda1` for the root disk, and this
  causes the machine to come up, shut down and terminate in a loop (and gets epensive, very quickly). Ooops.
  
- YAML syntax is nice (I'd not used it extensively, but wanted to for this challenge), but if you're unfamilliar with 
  the syntax it can take longer to figure out what's going on. 

Thanks for your time and consideration,

Sam