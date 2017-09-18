# squash-deployment
Manage the deployment of the squash microservices.


## SQuaSH microservices deployment

[squash-deployment](https://github.com/lsst-sqre/squash-deployment) will clone the repositories for the individual squash microservices, set the appropriate 
namespaces, create the secrets and deploy the microservices in the right order.

### SQuaSH DB

[squash-db](https://github.com/lsst-sqre/squash-db) provides a persistent installation of MariaDB on Kubernetes for SQuaSH


```
  make squash-db
```

![SQuaSH db microservice](figs/squash-db.png)


NOTE: if using minikube make the deployment using:
```
  MINIKUBE=true make squash-db
```

### Create the `tls-certs` secret

`tls-certs` is used by the [squash-api](https://github.com/lsst-sqre/squash-api), [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and the [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices which use `nginx` as reverse proxy. 

Download the `lsst-certs.git` repo from the [lsst-square](https://www.dropbox.com/home/lsst-sqre) Dropbox folder, it has the SSL key and certificates to secure
 traffic on `*.lsst.codes` services. 

```
  make tls-certs
```

### SQuaSH API

The [squash-api](https://github.com/lsst-sqre/squash-api) connects the [squash-db](https://github.com/lsst-sqre/squash-db), the [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and the [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices.

```
  make squash-api 
```

![SQuaSH DB and the API microservices](figs/squash-db-api.png)


### SQuaSH Bokeh
The [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) provides a Bokeh server and host the SQuaSH bokeh apps. Bokeh apps can be embedded in the [squash-dash](https://github.com/lsst-sqre/squash-dash) frontend or in the JupiterLab environment.
 
```
  make squash-bokeh
```

![SQuaSH DB, API and the Bokeh microservices](figs/squash-db-api-bokeh.png)


### SQuaSH Dash
The [squash-dash](https://github.com/lsst-sqre/squash-dash) is a frontend interface to embed the SQuaSH bokeh apps and display statistics from the SQuaSH API. 


```
  make squash-dash
```

![SQuaSH DB, API, Bokeh and the Dashboard microservices](figs/squash-deployment.png)


## Configure DNS for the services

We use AWS route53 to create DNS records for SQuaSH services. You have to set your 
AWS credentials and execute the command below for each service:

```
export AWS_ACCESS_KEY_ID=<your AWS credentials>
export AWS_SECRET_ACCESS_KEY=<your AWS credentials>
```

```
SQUASH_SERVICE=<name of the squash service> make dns
```

Output example:

```
$ SQUASH_SERVICE=squash-bokeh make dns
source terraform/tf_env.sh squash-bokeh squash-dev 35.203.172.87; 
	./terraform/bin/terraform apply -state=terraform/squash-bokeh.tfstate terraform/dns
aws_route53_record.squash-www: Creating...
  fqdn:              "" => "<computed>"
  name:              "" => "squash-bokeh.squash-dev.lsst.codes"
  records.#:         "" => "1"
  records.547640452: "" => "35.203.172.87"
  ttl:               "" => "300"
  type:              "" => "A"
  zone_id:           "" => "Z3TH0HRSNU67AM"
aws_route53_record.squash-www: Still creating... (10s elapsed)
aws_route53_record.squash-www: Still creating... (20s elapsed)
aws_route53_record.squash-www: Still creating... (30s elapsed)
aws_route53_record.squash-www: Still creating... (40s elapsed)
aws_route53_record.squash-www: Creation complete (ID: Z3TH0HRSNU67AM_squash-bokeh.squash-dev.lsst.codes_A)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

The DNS record can be removed with:

```
SQUASH_SERVICE=<name of the squash service> make remove-dns
```


## Environment variables
The following environment variables are used to exchange information among the pods:

- SQUASH_DB_HOST
- SQUASH_DB_PASSWORD
- SQUASH_API_HOST
- SQUASH_API_URL
- SQUASH_API_DEBUG
- SQUASH_BOKEH_HOST
- SQUASH_BOKEH_PORT
- SQUASH_BOKEH_URL
- SQUASH_DASH_HOST

