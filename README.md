# aws-iam-role-last-used-config-rule
Creates an AWS Config rule and Lambda to check all roles' last used compliance.

See: https://aws.amazon.com/blogs/security/continuously-monitor-unused-iam-roles-aws-config/

Housekeeping:

- Target region (in this example is the current region):
        
        MY_AWS_REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')

- S3 bucket where to save the zip function code package (the name, not the ARN):

        MY_AWS_S3_BUCKET_NAME=<MY S3 BUCKET NAME>
        
- Lambda layer ARN(s) (optional):

        MY_AWS_LAMBDA_LAYER_ARNS=<MY COMMA SEPARATED LAMBDA LAYER ARNS>

Delete previous deployment:

    aws cloudformation delete-stack --stack-name iam-role-last-used
        
Package function code and transform the template to point to zipped code on S3:

    aws cloudformation package --region $MY_AWS_REGION --template-file iam-role-last-used.yml \
    --s3-bucket $MY_AWS_S3_BUCKET_NAME \
    --output-template-file iam-role-last-used-transformed.yml

Peploy the lambda function:

    aws cloudformation deploy --region $MY_AWS_REGION --template-file iam-role-last-used-transformed.yml \
    --stack-name iam-role-last-used \
    --parameter-overrides NameOfSolution='iam-role-last-used' \
    MaxDaysForLastUsed=60 \
    RolePatternWhitelist='/breakglass-role|/security-*' \
    LambdaLayerArn="$MY_AWS_LAMBDA_LAYER_ARNS" \
    --capabilities CAPABILITY_NAMED_IAM
