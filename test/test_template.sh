#!/bin/sh
MY_S3_BUCKET_NAME=$1

MY_STACK_NAME=iam-role-last-used
MY_AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
MY_LAMBDA_LAYER_ARN_NO_ITEMS=
MY_LAMBDA_LAYER_ARN_1_ITEM="arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:18"
MY_LAMBDA_LAYER_ARN_2_ITEMS="arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:18,arn:aws:lambda:eu-west-1:434848589818:layer:AWS-AppConfig-Extension:69"
MY_LAMBDA_LAYER_ARN_WITH_SPACE="arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:18, arn:aws:lambda:eu-west-1:434848589818:layer:AWS-AppConfig-Extension:69"

test_count=0
passed_count=0
failed_count=0

function delete_stack {
    echo
    aws cloudformation delete-stack --stack-name $MY_STACK_NAME
    echo "Deleting stack..."
    aws cloudformation wait stack-delete-complete --stack-name $MY_STACK_NAME
    echo "Stack deleted."
}

function transform_template {
    echo
    echo "Packaging code and tranforming template..."
    echo "MY_S3_BUCKET_NAME: $MY_S3_BUCKET_NAME"
    aws cloudformation package --region $MY_AWS_REGION --template-file iam-role-last-used.yml \
    --s3-bucket $MY_S3_BUCKET_NAME \
    --output-template-file iam-role-last-used-transformed.yml
    echo "Template transformed."
}

function test_without_layer {
    
    delete_stack
    transform_template
    
    echo 
    echo "Testing without layer parameter..."

    aws cloudformation deploy --region $MY_AWS_REGION --template-file iam-role-last-used-transformed.yml \
    --stack-name $MY_STACK_NAME \
    --parameter-overrides NameOfSolution='iam-role-last-used' \
    MaxDaysForLastUsed=60 \
    RolePatternWhitelist='/breakglass-role|/security-*' \
    --capabilities CAPABILITY_NAMED_IAM
    rc=$?
    echo "RC: $rc"
    return $rc
    
}

function test_with_layer {
    
    delete_stack
    transform_template
    
    echo 
    echo "Testing with layer parameter: \"$1\"..."

    aws cloudformation deploy --region $MY_AWS_REGION --template-file iam-role-last-used-transformed.yml \
    --stack-name $MY_STACK_NAME \
    --parameter-overrides NameOfSolution='iam-role-last-used' \
    MaxDaysForLastUsed=60 \
    RolePatternWhitelist='/breakglass-role|/security-*' \
    LambdaLayerArn="$1" \
    --capabilities CAPABILITY_NAMED_IAM
    rc=$?
    echo "RC: $rc"
    return $rc
    
}

function assert_rc {
    echo
    local expected_rc=$1
    local actual_rc=$2
    (( test_count++ ))
    echo -n "Test number $test_count: "
    if (( actual_rc == expected_rc )); then
        (( passed_count++ ))
        echo "PASSED"
    else
        (( failed_count++ ))
        echo "FAILED"
    fi
}

function print_statistics {
    echo
    echo "*** Statistics ***"
    echo "TOTAL : $test_count"
    echo "PASSED: $passed_count"
    echo "FAILED: $failed_count"
}

test_without_layer
assert_rc 0 $?

test_with_layer "$MY_LAMBDA_LAYER_ARN_NO_ITEMS"
assert_rc 0 $?

test_with_layer "$MY_LAMBDA_LAYER_ARN_1_ITEM"
assert_rc 0 $?

test_with_layer "$MY_LAMBDA_LAYER_ARN_2_ITEMS"
assert_rc 0 $?

test_with_layer "$MY_LAMBDA_LAYER_ARN_WITH_SPACE"
assert_rc 254 $?

print_statistics

exit $failed_count
