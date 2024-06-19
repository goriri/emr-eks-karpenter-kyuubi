aws emr-containers start-job-run \
--virtual-cluster-id ${EMRCLUSTER_ID} \
--name spark-pi-pod-template \
--execution-role-arn ${JOB_EXECUTION_ROLE_ARN} \
--release-label emr-6.10.0-latest \
--job-driver '{
    "sparkSubmitJobDriver": {
        "entryPoint": "s3://aws-data-analytics-workshops/emr-eks-workshop/scripts/pi.py",
        "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=2 --conf spark.driver.cores=1"
        }
    }' \
--configuration-overrides '{
    "applicationConfiguration": [
      {
        "classification": "spark-defaults",
        "properties": {
          "spark.kubernetes.driver.podTemplateFile": "s3://'$S3_BUCKET'/pod-template/driver-pod-template.yaml",
          "spark.kubernetes.executor.podTemplateFile": "s3://'$S3_BUCKET'/pod-template/executor-pod-template.yaml"
         }
      }
    ]
  }'