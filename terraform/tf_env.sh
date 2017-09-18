SQUASH_SERVICE=$1
NAMESPACE=$2
EXTERNAL_IP=$3
export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
export TF_VAR_service_name=$SQUASH_SERVICE
export TF_VAR_namespace_name=$NAMESPACE
export TF_VAR_external_ip=$EXTERNAL_IP

