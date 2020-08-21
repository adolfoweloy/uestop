# uestop-infra

This project is the infrastructure definition for the uestop game and it is organised as follows:

```
modules
  +-admin
  +-common
  +-webserver
  +-worker
  main.tf
```

I am trying to use an approach where the Terraform modules are grouped by functionality e.g. webserver, instead of fine-grained approach like having separate modules for instances, launch configurations, auto-scaling groups and so on.

The description for each module is detailed as follows:

* __admin__: provides an instance that acts as a bastion/jump-box in order to allow SSH access to other instances such as the ones provided by workers and webservers.
* __common__: provides modules that can be reused such as security groups
* __webserver__: contains the necessary definitions in order to have instances available for the web-server service.
* __worker__: declares all that's needed for async processing through SQS queues.
