# tl;dr

Short instructions in case you are familiar with the [SQuaSH](https://squash.lsst.codes/) deployment already:
```
# Make sure kubectl is configured to access your GKE cluster
 
# Set an appropriate namespace for the deployment
export NAMESPACE=demo
make namespace 
 
# Create the TLS certificate secrets used by the SQuaSH services

# Download the `lsst-certs.git` repo 
make tls-certs
 
# Deploy the SQuaSH database
SQUASH_SERVICE=squash-db make clone 
cd squash-db
make passwd.txt
make deployment
cd ..
 
# Restore a copy of the SQuaSH production database (ok, this could be automated too)

export AWS_ACCESS_KEY_ID=<your AWS credentials>
export AWS_SECRET_ACCESS_KEY=<your AWS credentials>
 
aws s3 ls s3://jenkins-prod-qadb.lsst.codes-backups/squash-prod/
aws s3 cp s3://jenkins-prod-qadb.lsst.codes-backups/squash-prod/<YYYYMMDD-HHMM>/squash-db-mariadb-qadb-<YYYYMMDD-HHMM>.gz .
 
kubectl cp squash-db-mariadb-qadb-<YYYYMMDD-HHMM>.gz <squash-db pod>:/ 
kubectl exec -it <squash-db pod> /bin/bash
gzip -d squash-db-mariadb-qadb-<YYYYMMDD-HHMM>.gz 
mysql -uroot -p<passwd> qadb < squash-db-mariadb-qadb-<YYYYMMDD-HHMM>
 
# Deploy the SQuaSH REST API
SQUASH_SERVICE=squash-api make clone deployment name
 
# Deploy the bokeh server
SQUASH_SERVICE=squash-bokeh make clone deployment name
 
# Deploy the SQuaSH Dashboard
SQUASH_SERVICE=squash-dash make clone deployment name
```

## squash-deployment

This tool automates the steps required to deploy [SQuaSH](https://squash.lsst.codes/) it helps you to clone the individual microservice repositories, set up the appropriate 
Kubernetes namespace, create secrets and custom configurations and finally to create the Kubernetes deployments and names for the services.

If you are not familiar with microservices or Kubernetes concepts, we recommend this [tutorial](https://classroom.udacity.com/courses/ud615) from Kelsey Hightower. 

NOTE: some of the steps below will require your AWS credentials and access to the TLS certificates provided by SQuaRE. We use AWS Route 53 for the DNS and backu up the SQuaSG DB to AWS S3.

### Requirements

We assume that you have a Kubernetes cluster that you created on [GKE](https://cloud.google.com/kubernetes-engine/) as well as the [Google Cloud SDK](https://cloud.google.com/sdk/) and the Kubernetes command line client [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) installed.
 
To configure `kubectl` to connect to your cluster go to [Google Cloud Platform](https://cloud.google.com) > Google Kubernetes Engine, select your cluster and click `Connect` to get the cluster credentials.

We also assume you have your AWS credentials, we use AWS S3 for backups of the SQuaSH DB and AWS route53 for DNS configuration.

### Deployment namespace

A Kubernetes _namespace_ provides a scope for services, deployments, secrets and configurations in the cluster.
You can use any available namespace.

Namespaces are also used to define the context in which the `kubectl` client works.

Use the following to create a `demo` namespace and switch to the right context:
```
NAMESPACE=demo make namespace 
```

NOTE: by construction the Kubernetes namespace and the `kubectl` context have the same name.
 
Output example: 

```
$ NAMESPACE=demo make namespace
---
kubectl create -f kubernetes/namespace.yaml
namespace "demo" created
kubectl config set-context demo --namespace=demo --cluster=gke_radiant-moon-173517_us-west1-a_k0 --user=gke_radiant-moon-173517_us-west1-a_k0
Context "demo" created.
kubectl config use-context demo
Switched to context "demo".
```

A namespace can be removed with:

```
$ NAMESPACE=demo make remove-namespace
--
All previous Pods, Services, and Deployments in the "demo" namespace will be destroyed. Are you sure? [y/n]:y
namespace "demo" deleted
```

NOTE: There's a reserved namespace, `squash-prod`, used for the production deployment only.

### Create the `tls-certs` secret

TLS termination is implemented in the [squash-api](https://github.com/lsst-sqre/squash-api), [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices to secure traffic on the `*.lsst.codes` domain. 

Download the `lsst-certs.git` repo from the [lsst-square Dropbox folder](https://www.dropbox.com/home/lsst-sqre), it has the SSL key and certificates for the `*.lsst.codes` domain name. 

NOTE: if you are not SQuaRE you'll need help from a member of the team to access this folder.
 
Then use the following command to create the `tls-certs` secret.
 
```
make tls-certs
```

Output example:

```
$ make tls-certs
---
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
.......+................................................................+...................+.........................................+...............................................................................................................................................................................................................................................
Creating tls-certs secret...
Initialized empty Git repository in /Users/afausti/Projects/squash-deployment/lsst-certs/.git/
remote: Counting objects: 72, done.
remote: Compressing objects: 100% (61/61), done.
remote: Total 72 (delta 19), reused 27 (delta 7)
Unpacking objects: 100% (72/72), done.
From ../lsst-certs
 * branch            master     -> FETCH_HEAD
 * [new branch]      master     -> origin/master
cp lsst-certs/lsst.codes/2017/lsst.codes.key tls
cp lsst-certs/lsst.codes/2017/lsst.codes_chain.pem tls
kubectl delete --ignore-not-found=true secrets tls-certs
kubectl create secret generic tls-certs --from-file=tls
secret "tls-certs" created
```

### SQuaSH DB

[squash-db](https://github.com/lsst-sqre/squash-db) provides a persistent installation of `MariaDB` on Kubernetes for SQuaSH

```
SQUASH_SERVICE=squash-db make clone
cd squash-db
make passwd.txt
make deployment
cd ..

```

See instructions at [squash-db](https://github.com/lsst-sqre/squash-db) on how to load test data or restore a copy of
the current production database.

![SQuaSH db microservice](figs/squash-db.png)

### SQuaSH API

The [squash-api](https://github.com/lsst-sqre/squash-api) connects the [squash-db](https://github.com/lsst-sqre/squash-db) with the [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and the [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices.

```
SQUASH_SERVICE=squash-api make clone deployment
```

![SQuaSH DB and the API microservices](figs/squash-db-api.png)

### SQuaSH Bokeh
The [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) provides a Bokeh server and host the SQuaSH bokeh apps. Bokeh apps can be embedded in [squash-dash](https://github.com/lsst-sqre/squash-dash) or in the JupiterLab environment.
 
```
SQUASH_SERVICE=squash-bokeh make clone deployment
```

![SQuaSH DB, API and the Bokeh microservices](figs/squash-db-api-bokeh.png)

### SQuaSH Dash
The [squash-dash](https://github.com/lsst-sqre/squash-dash) is a frontend interface to embed the SQuaSH bokeh apps and display statistics from the SQuaSH API. 

```
SQUASH_SERVICE=squash-dash make clone deployment
```

![SQuaSH DB, API, Bokeh and the Dashboard microservices](figs/squash-deployment.png)

## Creating names for the services

We use AWS route53 to create DNS records for the SQuaSH services. You have to set your 
AWS credentials and execute the command below for the `squash-api`, `squash-bokeh` 
and `squash-dash` services.

```
export AWS_ACCESS_KEY_ID=<your AWS credentials>
export AWS_SECRET_ACCESS_KEY=<your AWS credentials>
```

```
NASMESPACE=<namespace> SQUASH_SERVICE=<name of the squash service> make name
```

Service names follow the pattern `<squash service>-<namespace>.lsst.codes`. 

NOTE: for the production deployment, the  services will be named like `<squash service>.lsst.codes`. 

Output example:

```
$ NAMESPACE=demo SQUASH_SERVICE=squash-bokeh make name
---
source terraform/tf_env.sh squash-bokeh demo 35.203.172.87; 
	./terraform/bin/terraform apply -state=terraform/squash-bokeh.tfstate terraform/dns
aws_route53_record.squash-www: Creating...
  fqdn:              "" => "<computed>"
  name:              "" => "squash-bokeh-demo.lsst.codes"
  records.#:         "" => "1"
  records.547640452: "" => "35.203.172.87"
  ttl:               "" => "300"
  type:              "" => "A"
  zone_id:           "" => "Z3TH0HRSNU67AM"
aws_route53_record.squash-www: Still creating... (10s elapsed)
aws_route53_record.squash-www: Still creating... (20s elapsed)
aws_route53_record.squash-www: Still creating... (30s elapsed)
aws_route53_record.squash-www: Still creating... (40s elapsed)
aws_route53_record.squash-www: Creation complete (ID: Z3TH0HRSNU67AM_squash-bokeh-demo.lsst.codes_A)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

A DNS record can be removed with:

```
NAMESPACE=<namespace> SQUASH_SERVICE=<name of the squash service> make remove-name
```

That's it, you should be able to access SQuaSH from `https://squash-<namespace>.lsst.codes`.
