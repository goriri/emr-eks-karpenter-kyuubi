# Create kubernetes namespace for EMR on EKS
kubectl create namespace $EMR_NAMESPACE

# Enable cluster access for Amazon EMR on EKS in the 'emr' namespace
eksctl create iamidentitymapping --cluster $CLUSTER_NAME --namespace $EMR_NAMESPACE --service-name "emr-containers"
aws emr-containers update-role-trust-policy --cluster-name $CLUSTER_NAME --namespace $EMR_NAMESPACE --role-name $JOB_EXECUTION_ROLE_NAME

# Create emr virtual cluster
aws emr-containers create-virtual-cluster --name $EMRCLUSTER_NAME \
  --container-provider '{
        "id": "'$CLUSTER_NAME'",
        "type": "EKS",
        "info": { "eksInfo": { "namespace": "'$EMR_NAMESPACE'" } }
    }'

# Create a kyuubi service account for the spark driver in emr namespace
eksctl create iamserviceaccount \
 --name $KYUUBI_SA \
 --namespace $EMR_NAMESPACE \
 --cluster $CLUSTER_NAME \
 --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/$JOB_EXECUTION_POLICY_NAME \
 --approve

# Create the driver RBAC role
kubectl apply -f emr-containers-driver-role.yaml

# Bind the kyuubi sa to the driver RBAC role
envsubst <./kyuubi-sa-rolebinding.yaml | kubectl apply -f -
