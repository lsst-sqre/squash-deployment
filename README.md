# tl;dr

Short instructions in case you are familiar with the [SQuaSH](https://squash.lsst.codes/) deployment:
```
# Make sure kubectl is configured to access your GKE cluster

# Set an appropriate namespace for the deployment
export NAMESPACE=demo
make namespace

# Create the TLS certificate secrets used by the SQuaSH services

# Download the `lsst-certs.git` repo containing the most recent SSL certificates (or ask SQuaRE if you don't know about it)
# Make sure the folder is unzipped
make tls-certs

# Deploy the SQuaSH REST API
SQUASH_SERVICE=squash-restful-api make clone

cd squash-restful-api

# Create secret with the Cloud SQL Proxy key and the database password
export PROXY_KEY_FILE_PATH=<path to the JSON file with the SQuaSH Cloud SQL service account key.>
export SQUASH_DB_PASSWORD=<password created for the user `proxyuser` when the Cloud SQL instance was configured.>
make cloudsql-secret

# Name of the Cloud SQL instance to use
export INSTANCE_CONNECTION_NAME=<name of the cloudsql instance>

# Create secret with AWS credentials
export AWS_ACCESS_KEY_ID=<the aws access key id>
export AWS_SECRET_ACCESS_KEY=<the aws secret access key>
make aws-secret

# Create the S3 bucket for this deployment
make s3-bucket  

# Set the application default user
export SQUASH_DEFAULT_USER=<the squash api admin user>
export SQUASH_DEFAULT_PASSWORD=<password for the squash api admin user>

TAG=latest make service deployment

# Create the service name
cd ..

export SQUASH_SERVICE=squash-restful-api
make name

# Deploy the bokeh server
SQUASH_SERVICE=squash-bokeh make clone deployment name

# Deploy the SQuaSH frontend
SQUASH_SERVICE=squash make clone deployment name
```

## squash-deployment

This tool automates [SQuaSH](https://squash.lsst.codes/) deployment helping you  cloning the repositories involved, setting up the appropriate
deployment namespace, creating secrets and custom configurations.

If you are not familiar with microservices or k8s concepts, a good resource is this [tutorial](https://classroom.udacity.com/courses/ud615) from Kelsey Hightower.

### Requirements

We assume that you have a k8s cluster on [GKE](https://cloud.google.com/kubernetes-engine/) and the required tools installed, like the [Google Cloud SDK](https://cloud.google.com/sdk/), Docker and the [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) client.

To configure `kubectl` to connect to your cluster go to [Google Cloud Platform](https://cloud.google.com) > Google Kubernetes Clusters, select your cluster and click `Connect` to get the cluster credentials.

We also assume that you have your AWS credentials - we use AWS route53 for DNS configuration and AWS S3 to store verification datasets sent to SQuaSH.

### Deployment namespace

A k8s _namespace_ provides a scope for services, deployments, secrets and configurations in the cluster. You can use any available namespace.

Namespaces are also used to define the context in which the `kubectl` client works.

Use the following to create a `demo` namespace and context:

```
NAMESPACE=demo make namespace
```

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

You can switch to an existing namespace using:
```
NAMESPACE=demo make switch-namespace
```

And a namespace can be removed with:

```
$ NAMESPACE=demo make remove-namespace
--
All previous Pods, Services, and Deployments in the "demo" namespace will be destroyed. Are you sure? [y/n]:y
namespace "demo" deleted
```

NOTE: There's a reserved namespace, `squash-prod` used for the production deployment.

### Create the `tls-certs` secret

TLS termination is implemented in the [squash-api](https://github.com/lsst-sqre/squash-api), [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices to secure traffic on the `*.lsst.codes` domain.

The SSL key and certificates for the `*.lsst.codes` domain name can be downloaded from this bare repo at [lsst-certs](https://www.dropbox.com/home/lsst-sqre/git)

You'll have to sign in to Dropbox to download the `lsst-certs.git`, make sure it is in the current directory and is unziped.

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


Follow each microservice repository for detailed deployment instructions.


* [squash-restful-api](https://github.com/lsst-sqre/squash-restful-api): The SQuaSH RESTful API is a Flask application used to manage the metrics dashboard. It also uses Celery to enable the execution of tasks in background.

* [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh): it serves the squash bokeh apps, we use the Bokeh plotting library for rich interactive visualizations.

* [squash](https://github.com/lsst-sqre/squas) is the web frontend to embed the bokeh apps and navigate through the bokeh apps.


![SQuaSH deployment architecture](figs/squash-deployment.png)

## Creating names for the services

We use AWS route53 to create DNS records for the SQuaSH services. You have to set your
AWS credentials and execute the command below for the `squash-restful-api`, `squash-bokeh`
and `squash` services.

```
export AWS_ACCESS_KEY_ID=<your AWS credentials>
export AWS_SECRET_ACCESS_KEY=<your AWS credentials>
```

```
NASMESPACE=<namespace> SQUASH_SERVICE=<name of the squash service> make name
```

Service names follow the pattern `<squash service>-<namespace>.lsst.codes`.

For the production deployment, which uses the reserved namespace `<squash-prod>` the  services will be named like `<squash service>.lsst.codes`.

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

Note that the `terraform` state is saved for each service and namespace.

A DNS record can be removed with:

```
NAMESPACE=<namespace> SQUASH_SERVICE=<name of the squash service> make remove-name
```

That's it, you should be able to access SQuaSH from `https://squash-<namespace>.lsst.codes`.


# Deploying Telegraf for monitoring

Deploy Tiller, the server portion of Helm.

You can do that on the `kube-system` namespace, and create a service account with `cluster-admin` role, but see [Helm and RBAC](https://docs.helm.sh/using_helm/#role-based-access-control) for other options.

```
kubectl create -f kubernetes/rbac-config.yaml
helm init --service-account tiller
```

Deploy Telegraf

```
helm install ./telegraf-ds
```

See [telegraf-ds](telegraf-ds/README.md) for more information.


# Updating SSL certificates

- Go to squash-deployment folder used to deploy a particular SQuaSH instance
- Download the new SSL certificates, currently the `lsst-certs.git` repo from the `lsst-square` Dropbox folder
- Update `LSST_CERTS_YEAR` variable to the current year in the Makefile
- Remove the previous `tls` folder
- Run make `tls-certs`
