# Demo How to Setup EMR on EKS with Kyuubi and Karpenter with Steps Explained
## Step 0 Create a EKS Cluster with Karpenter installed
Following the steps 1-4 in https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/. 
Recommend to change instance type to m6i.large, CLUSTER_NAME=EMR_EKS
```
export AWS_REGION = ${AWS_DEFAULT_REGION}
export DEFAULT_AZ = ${AWS_REGION}a
```
## Step 1 Add Service Accounts to Your EKS Cluster
Create the EMR job execution which has access to your S3 bucket
```
export JOB_EXECUTION_ROLE_NAME=${EKSCLUSTER_NAME}-execution-role
export JOB_EXECUTION_POLICY_NAME=${EKSCLUSTER_NAME}-execution-policy
export JOB_EXECUTION_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${JOB_EXECUTION_ROLE_NAME}

export S3_BUCKET="YOUR_BUCKET"
export EMR_NAMESPACE=emr
export KYUUBI_NAMESPACE=kyuubi
export KYUUBI_SA=emr-kyuubi

./job-execution-role.sh
```
Create the ebs controller service account 
Is this needed? cross account kyuubi execution service account
```
envsubst < service-accounts.yaml | eksctl create iamserviceaccount --config-file=-
```
## Step 2 Setup EMR on EKS
```
export EMRCLUSTER_NAME=${CLUSTER_NAME}-emr
./emr-setup.sh
```

## Step 3 Test The Vanilla Job Run
```
./start-job-run-test.sh
```

## Step 4 Create Karpenter NodePool & Pod Templates
```
envsubst < karpenter-emr-nodepool.yaml | kubectl apply -f -
```