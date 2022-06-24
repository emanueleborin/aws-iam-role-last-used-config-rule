# aws-iam-role-last-used-config-rule
Creates an AWS Config rule and Lambda to check all roles' last used compliance.

See: https://aws.amazon.com/blogs/security/continuously-monitor-unused-iam-roles-aws-config/

To package lambda code and tranform template to point to it on S3:

    aws cloudformation package --region $AWS_REGION --template-file iam-role-last-used.yml \
    --s3-bucket $S3_BUCKET_NAME \
    --output-template-file iam-role-last-used-transformed.yml
