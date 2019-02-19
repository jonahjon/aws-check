#!/bin/bash
# $1 is the $ARTIFACT_BUCKET from CodePipeline

# run aws cloudformation validate-template and cfn_nag_scan on all **local** templates
export deployment_dir=`pwd`
echo "$deployment_dir/"
for i in $(find . -type f | grep '.yml$' | sed 's/^.\///') ; do
    echo "Running aws cloudformation validate-template on $i"
    aws s3 cp $deployment_dir/$i s3://$1/validate/templates/$i
    aws cloudformation validate-template --template-url https://s3.$AWS_REGION.amazonaws.com/$1/validate/templates/$i --region $AWS_REGION
    if [ $? -ne 0 ]
    then
      echo "CloudFormation template failed validation - $i"
      exit 1
    fi
    # if you want to delete validation objects
    #aws s3 rm s3://$1/validate/templates/$i
    echo "Running cfn_nag_scan on $i"
    cfn_nag_scan --input-path $deployment_dir/$i
    if [ $? -ne 0 ]
    then
      echo "CFN Nag failed validation - $i"
      exit 1
    fi
done

# run json validation on all the **local** parameter files

cd ../parameters
export deployment_dir=`pwd`
echo "$deployment_dir/"
for i in $(find . -type f | grep '.json' | grep -v '.j2' | sed 's/^.\///') ; do
    echo "Running json validation on $i"
    python -m json.tool < $i
    if [ $? -ne 0 ]
    then
      echo "CloudFormation parameter file failed validation - $i"
      exit 1
    fi
done
cd ..
