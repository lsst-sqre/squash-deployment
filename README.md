# squash-deployment
Manage the deployment of the squash microservices.


[squash-deployment](https://github.com/lsst-sqre/squash-deployment) will clone the repositories for the individual squash microservices, set the appropriate 
namespace and context, create secrets, deployments and the DNS records for the services.

### Deployment namespace

A Kubernetes _namespace_ provides a scope for Pods, Services, and Deployments in the cluster.
You can use any available namespace.

Namespaces are also used to define a context in which the `kubectl` client works.

Use the following to create a `squash-dev` namespace and switch to the right context:
```
NAMESPACE=squash-dev make create-namespace 
```

Output example: 

```
$ NAMESPACE=squash-dev make create-namespace
---
kubectl create -f kubernetes/namespace.yaml
namespace "squash-dev" created
kubectl config set-context squash-dev --namespace=squash-dev --cluster=gke_radiant-moon-173517_us-west1-a_k0 --user=gke_radiant-moon-173517_us-west1-a_k0
Context "squash-dev" created.
kubectl config use-context squash-dev
Switched to context "squash-dev".
```

A namespace can be removed with:

```
$ NAMESPACE=squash-dev make remove-namespace
--
All previous Pods, Services, and Deployments in the "squash-dev" namespace will be destroyed. Are you sure? [y/n]:y
namespace "squash-dev" deleted
```

NOTE: There's a reserved namespace, `squash-prod`, used by the production deployment only.

### Create the `tls-certs` secret

TLS termination is implemented in the [squash-api](https://github.com/lsst-sqre/squash-api), [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices to secure traffic on the `*.lsst.codes` domain. 

Download the `lsst-certs.git` repo from the [lsst-square Dropbox folder](https://www.dropbox.com/home/lsst-sqre), it has the SSL key and certificates. Use the following to create the `tls-certs` secret.
 
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

[squash-db](https://github.com/lsst-sqre/squash-db) provides a persistent installation of `mariadb` on Kubernetes for SQuaSH

```
SQUASH_SERVICE=squash-db make clone deployment
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
The [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) provides a Bokeh server and host the SQuaSH bokeh apps. Bokeh apps can be embedded in the [squash-dash](https://github.com/lsst-sqre/squash-dash) frontend or in the JupiterLab environment.
 
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

## Creating DNS records for the services

We use AWS route53 to create DNS records for the SQuaSH services. You have to set your 
AWS credentials and execute the command below for the `squash-api`, `squash-bokeh` 
and `squash-dash` services.

```
export AWS_ACCESS_KEY_ID=<your AWS credentials>
export AWS_SECRET_ACCESS_KEY=<your AWS credentials>
```

```
SQUASH_SERVICE=<name of the squash service> make create-dns
```

Service names follow the pattern `<name of the squash service>-<namespace>.lsst.codes`. 

NOTE: The `squash-prod` _namespace_ is reserved for the production deployment and will
be removed from the service name.

Output example:

```
$ SQUASH_SERVICE=squash-bokeh make create-dns
---
source terraform/tf_env.sh squash-bokeh squash-dev 35.203.172.87; 
	./terraform/bin/terraform apply -state=terraform/squash-bokeh.tfstate terraform/dns
aws_route53_record.squash-www: Creating...
  fqdn:              "" => "<computed>"
  name:              "" => "squash-bokeh-squash-dev.lsst.codes"
  records.#:         "" => "1"
  records.547640452: "" => "35.203.172.87"
  ttl:               "" => "300"
  type:              "" => "A"
  zone_id:           "" => "Z3TH0HRSNU67AM"
aws_route53_record.squash-www: Still creating... (10s elapsed)
aws_route53_record.squash-www: Still creating... (20s elapsed)
aws_route53_record.squash-www: Still creating... (30s elapsed)
aws_route53_record.squash-www: Still creating... (40s elapsed)
aws_route53_record.squash-www: Creation complete (ID: Z3TH0HRSNU67AM_squash-bokeh-squash-dev.lsst.codes_A)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

The DNS record can be removed with:

```
SQUASH_SERVICE=<name of the squash service> make remove-dns
```

## Environment variables
The following environment variables are used by the deployment:

- SQUASH_DB_HOST
- SQUASH_DB_PASSWORD
- SQUASH_API_HOST
- SQUASH_API_URL
- SQUASH_API_DEBUG
- SQUASH_BOKEH_HOST
- SQUASH_BOKEH_PORT
- SQUASH_BOKEH_URL
- SQUASH_DASH_HOST

