SHELL := /bin/bash

# Downloaded from the `lsst-square` Dropbox folder
LSST_CERTS_REPO = lsst-certs.git
LSST_CERTS_YEAR = 2017

# Keys and certificates used in nginx config
SSL_KEY = lsst.codes.key
SSL_CERT = lsst.codes_chain.pem

# SSL config also requires a dhparam file
SSL_DH = dhparam.pem

# Output dirs
LSST_CERTS_DIR = lsst-certs
TLS_DIR = tls

$(TLS_DIR)/$(SSL_DH):
	mkdir -p $(TLS_DIR)
	openssl dhparam -out $(TLS_DIR)/$(SSL_DH) 2048

.PHONY: tls-certs
tls-certs: $(TLS_DIR)/$(SSL_DH)
	@echo "Creating tls-certs secret..."

	mkdir -p $(LSST_CERTS_DIR)
	cd $(LSST_CERTS_DIR); git init; git remote add origin ../$(LSST_CERTS_REPO); git pull origin master

	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_KEY) $(TLS_DIR)
	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_CERT) $(TLS_DIR)

	kubectl delete --ignore-not-found=true secrets tls-certs
	kubectl create secret generic tls-certs --from-file=$(TLS_DIR)

# Create Kubernetes deloyment

SQUASH_DB_PASSWD = squash-db/passwd.txt

$(SQUASH_DB_PASSWD):
	@echo "Enter a password for the SQuaSH DB:"
	@read MYSQL_PASSWD
	@echo $MYSQL_PASSWD > $(SQUASH_DB_PASSWD)

REPO_URL = https://github.com/lsst-sqre/${SQUASH_SERVICE}.git

clone: check_service
	git clone $(REPO_URL)

deployment:
	TAG=latest $(MAKE) deployment -C ${SQUASH_SERVICE}

# Create AWS route53 resources

TERRAFORM = ./terraform/bin/terraform

$(TERRAFORM):
	$(MAKE) -C terraform

EXTERNAL_IP = $(shell kubectl get service ${SQUASH_SERVICE} -o jsonpath --template='{.status.loadBalancer.ingress[0].ip}')

# By construction the context name is the same as the namespace name
NAMESPACE = $(shell kubectl config current-context)

.PHONY: dns
dns: $(TERRAFORM) check-service check-aws-creds
	source terraform/tf_env.sh ${SQUASH_SERVICE} $(NAMESPACE) $(EXTERNAL_IP); \
	$(TERRAFORM) apply -state=terraform/${SQUASH_SERVICE}.tfstate terraform/dns

remove-dns: $(TERRAFORM) check-service check-aws-creds
	source terraform/tf_env.sh; \
	$(TERRAFORM) destroy -state=terraform/${SQUASH_SERVICE}.tfstate

check-service:
	@if test -z ${SQUASH_SERVICE}; then echo "Error: SQUASH_SERVICE is undefined."; exit 1; fi

check-aws-creds:
	@if test -z ${AWS_ACCESS_KEY_ID}; then echo "Error: AWS_ACCESS_KEY_ID is undefined."; exit 1; fi
	@if test -z ${AWS_SECRET_ACCESS_KEY}; then echo "Error: AWS_SECRET_ACCESS_KEY is undefined."; exit 1; fi

.PHONY: clean
clean:
	rm -rf $(LSST_CERTS_DIR)
	rm -rf $(TLS_DIR)

