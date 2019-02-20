#!/bin/bash
# $1 is the $ARTIFACT_BUCKET from CodePipeline

# run aws cloudformation validate-template and cfn_nag_scan on all **local** templates
echo $AWS_REGION
echo $1
export deployment_dir=`pwd`
rm -rf buildspec.yml
echo "$deployment_dir/"
for i in $(find . -type f | grep '.yml$' | sed 's/^.\///') ; do
    echo "Running aws cloudformation validate-template on $i"
    echo $deployment_dir/$i
    aws s3 cp $deployment_dir/$i s3://$1/validate/templates/$i
    aws cloudformation validate-template --template-url https://s3.$AWS_REGION.amazonaws.com/$1/validate/templates/$i --region $AWS_REGION
    if [ $? -ne 0 ]
    then
      echo "CloudFormation template failed validation - $i"
      exit 1
    fi
    echo "Running cfn_nag_scan on $i"
    cfn_nag_scan --input-path $deployment_dir/$i > report_$i.txt
    if [ $? -ne 0 ]
    then
      echo "CFN Nag failed validation - $i"
      exit 1
    fi
    # if you want to copy validated templates to your artifacts
    aws s3 cp $deployment_dir/$i s3://$1/validate/templates/$i
    # if you want to delete them as well...
    aws s3 rm s3://$1/validate/templates/$i
done
