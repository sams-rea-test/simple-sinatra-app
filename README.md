REA Systems Engineer practical task
===================================

Hi there! Thanks for reviewing my practical tests. I hope it's at least a little interesting and not a complete flop.
I hope it's not too obvious that ruby apps aren't my strong point when assessing.

## Assumptions I've made

Hi there! Just to be super clear, here are some of the assumptions that I've made with what is acceptible for our 
application's infrastructure:

- Developing and deploying using Docker is acceptable
- Using the official ruby docker images - based on Debian Jessie - is acceptable (although as noted in the `Dockerfile`,
   converting to Alpine or Centos is achievable as well, and if RHEL is more your taste, that could be done, too.) 
- Deploying the application onto AWS and EC2 Container Services (ECS) is acceptable
- Using CloudFormation to provision the infrastructure is acceptable (but unofficial AWS management tools like 
   Terraform could also be used instead).

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
