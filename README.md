# aws-iam-role-last-used-config-rule
Creates an AWS Config rule and Lambda to check all roles' last used compliance.

See: https://aws.amazon.com/blogs/security/continuously-monitor-unused-iam-roles-aws-config/

Housekeeping:

- target region (in this example current region):
        
        AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')

- S3 bucket where to save the zip function code package (the name, not the ARN):

        S3_BUCKET_NAME=<my bucket name>
        
Package function code and tranform the template to point to zipped code on S3:

    aws cloudformation package --region $AWS_REGION --template-file iam-role-last-used.yml \
    --s3-bucket $S3_BUCKET_NAME \
    --output-template-file iam-role-last-used-transformed.yml

Peploy lambda function:

    aws cloudformation deploy --region $AWS_REGION --template-file iam-role-last-used-transformed.yml \
    --stack-name iam-role-last-used \
    --parameter-overrides NameOfSolution='iam-role-last-used' \
    MaxDaysForLastUsed=60 \
    RolePatternWhitelist='/breakglass-role|/security-*' \
    LambdaLayerArn='' \
    --capabilities CAPABILITY_NAMED_IAM
