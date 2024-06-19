# The permission here is just for demo purposes. Please limit the access according to your requirements.
aws iam create-policy --policy-name $JOB_EXECUTION_POLICY_NAME --policy-document file://emr-job-execution-policy.json
aws iam create-role --role-name $JOB_EXECUTION_ROLE_NAME --assume-role-policy-document file://eks-trust-policy.json
aws iam attach-role-policy --role-name $JOB_EXECUTION_ROLE_NAME --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$JOB_EXECUTION_POLICY_NAME