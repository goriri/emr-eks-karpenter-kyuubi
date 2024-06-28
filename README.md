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

aws s3 mb s3://emr-eks-$AWS_ACCOUNT_ID
export S3_BUCKET=emr-eks-$AWS_ACCOUNT_ID
export EMR_NAMESPACE=emr
<!-- export KYUUBI_NAMESPACE=kyuubi -->
export KYUUBI_SA=emr-kyuubi

chmod +x job-execution-role.sh
./job-execution-role.sh
```
Create the ebs controller service account 
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
Please replace the EMRCLUSTER_ID with your EMR virtual cluster ID (can be found in the console EMR/EMR on EKS/Virtual Clusters)
```
export EMRCLUSTER_ID=ekjfutq5yadjc6626hmptqiq1
chmod +x start-job-run.sh
./start-job-run.sh
```

## Step 5 Create Pod Templates and Test
In the pod template, we will add node selection to run EMR workloads only on nodes labeled `app=emr` and let 
```
aws s3 cp driver-pod-template.yaml s3://${S3_BUCKET}/pod-template/
aws s3 cp executor-pod-template.yaml s3://${S3_BUCKET}/pod-template/

chmod +x start-job-run-pod-template.sh
./start-job-run-pod-template.sh
```

## Step 6 Create Kyuubi Image and Deploy
Option 1: Build your own Kyuubi image
```
export ECR_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
chmod +x build-kyuubi-docker.sh
./build-kyuubi-docker.sh
```
Option 2: Use the public image: public.ecr.aws/l2l6g0y5/emr-eks-kyuubi:6.10_180
```
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
export ECR_URL=public.ecr.aws/l2l6g0y5
```
Deploy the helm chart
```
envsubst < charts/my-kyuubi-values.yaml | helm install kyuubi charts/kyuubi -n emr --create-namespace -f - --debug
kubectl get pods -n emr
```

## Step 7 Login the Kyuubi Pod and Test It
```
kubectl exec -it pod/kyuubi-0 -n emr -- bash
```
```
# execute in the Kyuubi pod's shell. Spark submit test
export S3_BUCKET="YOUR_BUCKET"
aws s3 cp /usr/lib/spark/examples/jars/spark-examples s3://${S3_BUCKET}/jars

/usr/lib/spark/bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--conf spark.executor.instances=5 \
 s3://${S3_BUCKET}/jars/spark-examples.jar 10000
```
```
# beeline test
./bin/beeline -u 'jdbc:hive2://kyuubi-0.kyuubi-headless.emr.svc.cluster.local:10009#spark.app.name=b1;' -n hadoop --hiveconf spark.kubernetes.file.upload.path=s3://${S3_BUCKET}/upload_files/ --hiveconf spark.executor.instances=4 --hiveconf spark.driver.memory=4G --hiveconf spark.driver.cores=4
```