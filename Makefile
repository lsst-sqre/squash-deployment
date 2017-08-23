all:
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

.PHONY: clean

clean:
	rm -rf $(LSST_CERTS_DIR)
	rm -rf $(TLS_DIR)

