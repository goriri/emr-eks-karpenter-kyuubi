# Demo How to Setup EMR on EKS with Kyuubi and Karpenter with Steps Explained
# Step -1
Make sure you have aws credentials setup, aws cli, eksctl (https://eksctl.io/installation/), kubectl (1.30, https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), helm (https://helm.sh/docs/intro/install/) installed.
If you're using cloud9 as your IDE, make sure you have AWS managed temporary credential turned off and remove the `aws_session_token = ` line ~/.aws/credentials.

## Step 0 Create a EKS Cluster with Karpenter installed
Following the steps 1-4 in https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/. 
Recommend to change instance type to m6i.large, CLUSTER_NAME=EMR_EKS
DEFAULT_AZ not necessarily a
```
export AWS_REGION=${AWS_DEFAULT_REGION}
export DEFAULT_AZ=${AWS_REGION}d

aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
```
## Step 1 Add Service Accounts to Your EKS Cluster
Create the EMR job execution which has access to your S3 bucket
```
export JOB_EXECUTION_ROLE_NAME=${CLUSTER_NAME}-execution-role
export JOB_EXECUTION_POLICY_NAME=${CLUSTER_NAME}-execution-policy
export JOB_EXECUTION_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${JOB_EXECUTION_ROLE_NAME}

export S3_BUCKET="YOUR_BUCKET"
export EMR_NAMESPACE=emr
export KYUUBI_NAMESPACE=kyuubi
export KYUUBI_SA=emr-kyuubi

chmod +x job-execution-role.sh
./job-execution-role.sh
```
Create the ebs controller service account 
Is this needed? cross account kyuubi execution service account
```
envsubst < service-accounts.yaml | eksctl create iamserviceaccount --config-file=- --approve
```
## Step 2 Setup EMR on EKS
```
export EMRCLUSTER_NAME=${CLUSTER_NAME}-emr
chmod +x emr-setup.sh
./emr-setup.sh
```
## Step 3 Create Karpenter NodePool
```
envsubst < karpenter-emr-nodepool.yaml | kubectl apply -f -
```

## Step 4 Test The Vanilla Job Run
Please replace the EMRCLUSTER_ID with your EMR virtual cluster ID
```
export EMRCLUSTER_ID=ekjfutq5yadjc6626hmptqiq1
chmod +x start-job-run-test.sh
./start-job-run-test.sh
```

## Step 5 Create Pod Templates
```
aws s3 cp driver-pod-template.yaml s3://${S3_BUCKET}/pod-template/
aws s3 cp executor-pod-template.yaml s3://${S3_BUCKET}/pod-template/
```