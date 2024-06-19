aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# create a new repository in your ECR, **ONE-OFF task**
aws ecr create-repository --repository-name kyuubi-emr-eks --image-scanning-configuration scanOnPush=true

docker buildx build --platform linux/amd64,linux/arm64 \
-t $ECR_URL/kyuubi-emr-eks:6.10_180 \
-f ./Dockerfile --push .