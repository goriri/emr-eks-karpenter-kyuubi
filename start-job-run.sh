aws emr-containers start-job-run \
--virtual-cluster-id ${EMRCLUSTER_ID} \
--name spark-pi \
--execution-role-arn ${JOB_EXECUTION_ROLE_ARN} \
--release-label emr-6.10.0-latest \
--job-driver '{
    "sparkSubmitJobDriver": {
        "entryPoint": "s3://aws-data-analytics-workshops/emr-eks-workshop/scripts/pi.py",
        "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=2 --conf spark.driver.cores=1"
        }
    }' 