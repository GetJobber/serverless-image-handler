# Jobber Custom AWS Serverless Image based on v4.0.0
This custom build is created to address these 2 problems
- Support regex in environment variable `SOURCE_BUCKETS` ie. `jobber\-development\-.*` Instead of a comma separate list that includes all 50+ developer's S3 buckets. The CSV is not scalable and not maintainable.
- Fix SmartCrop since v4.0.0 broke on it and origin repo has no fix as time of writing this.

## Building a custom image
```
docker build -t serverless-image-handler .  # this builds the image
docker run -i -t serverless-image-handler /bin/bash.  # this starts a container using above image, and /bin/bash into it.
```

Once you are in the container, run the build script to generate a .zip package.
```
bash-4.2# cd deployment/
bash-4.2# ./build-s3-dist.sh $DIST_OUTPUT_BUCKET $TEMPLATE_OUTPUT_BUCKET $VERSION
```
You will see a new folder created call `dist` inside the `deployment` folder above. You can confirm by
```
bash-4.2# ls -al dist
total 33792
drwxr-xr-x 3 root root     4096 Jul 30 23:03 .
drwxr-xr-x 1 root root     4096 Jul 30 23:02 ..
-rw-r--r-- 1 root root   876367 Jul 30 23:03 custom-resource.zip
drwxr-xr-x 2 root root     4096 Jul 30 23:03 demo-ui
-rw-r--r-- 1 root root       88 Jul 30 23:03 demo-ui-manifest.json
-rw-r--r-- 1 root root 33676835 Jul 30 23:03 image-handler.zip
-rw-r--r-- 1 root root    30340 Jul 30 23:02 serverless-image-handler.template
```
There! You have now built 3 `.zip` packages for lambda to use.

## Extract and upload the images you built to S3
In order for AWS lambda image resizing server to use your lambda functions, you will have to upload the `.zip` files you built in the step above to S3. This step assumes you have setup your AWS credentials here: https://jobber.atlassian.net/wiki/spaces/JTW/pages/470777891/Deploying+Lambdas+WIP#DeployingLambdas(WIP)-Setup

### Extract
To extract files form a docker container, you can do the following, this copies the whole `dist` folder to the current directory you are in.
```
docker cp <docker_container_id>:/tmp/deployment/dist .
```
ie. for container ID `c376c5a86485`
```
docker cp c376c5a86485:/tmp/deployment/dist .
```

### Upload to S3
Uploads to 2 buckets, `jobber-development-harriswong-lambda-us-east-1` and `jobber-development-harriswong-lambda`.
`jobber-development-harriswong-lambda` stores the template
`jobber-development-harriswong-lambda-us-east-1` stores the `.zip` which is what the lambda server uses.
```
aws s3 cp ./dist/ s3://jobber-development-harriswong-lambda-us-east-1/serverless-image-handler/v4.0.0/ --recursive --exclude "*" --include "*.zip"
aws s3 cp ./dist/serverless-image-handler.template s3://jobber-development-harriswong-lambda/serverless-image-handler/v4.0.0/
```

## Deploying to dev environment
Deploy `./dist/serverless-image-handler.template` to CloudFormation with the following
```
aws cloudformation deploy --template-file serverless-image-handler.template --stack-name ServerlessImageHandler --no-execute-changeset --region=us-east-1 --parameter-overrides CorsEnabled='Yes' CorsOrig='*' SourceBuckets='jobber\-development\-.*' LambdaLogRetentionPeriod=30 DeployDemoUI='No' --capabilities CAPABILITY_NAMED_IAM
```


# ------ Below are the original AWS doc -------

# AWS Serverless Image Handler Lambda wrapper for SharpJS
A solution to dynamically handle images on the fly, utilizing Sharp (https://sharp.pixelplumbing.com/en/stable/).
Published version, additional details and documentation are available here: https://aws.amazon.com/solutions/serverless-image-handler/

_Note:_ it is recommend to build the application binary on Amazon Linux.

## Running unit tests for customization
* Clone the repository, then make the desired code changes
* Next, run unit tests to make sure added customization passes the tests
```
cd ./deployment
chmod +x ./run-unit-tests.sh  \n
./run-unit-tests.sh \n
```

## Building distributable for customization
* Configure the bucket name of your target Amazon S3 distribution bucket
```
export TEMPLATE_OUTPUT_BUCKET=my-bucket-name # bucket where cfn template will reside
export DIST_OUTPUT_BUCKET=my-bucket-name # bucket where customized code will reside
export VERSION=my-version # version number for the customized code
```
_Note:_ You would have to create 2 buckets, one named 'my-bucket-name' and another regional bucket named 'my-bucket-name-<aws_region>'; aws_region is where you are testing the customized solution. Also, the assets  in bucket should be publicly accessible.

```
* Clone the github repo
```bash
git clone https://github.com/awslabs/serverless-image-handler.git
```

* Navigate to the deployment folder
```bash
cd serverless-image-handler/deployment
```

* Now build the distributable
```bash
sudo ./build-s3-dist.sh $DIST_OUTPUT_BUCKET $TEMPLATE_OUTPUT_BUCKET $VERSION
```

* Deploy the distributable to an Amazon S3 bucket in your account. Note: you must have the AWS Command Line Interface installed.
```bash
aws s3 cp ./dist/ s3://$DIST_OUTPUT_BUCKET-[region_name]/serverless-image-handler/$VERSION/ --recursive --exclude "*" --include "*.zip"
aws s3 cp ./dist/serverless-image-handler.template s3://$TEMPLATE_OUTPUT_BUCKET/serverless-image-handler/$VERSION/
```
_Note:_ In the above example, the solution template will expect the source code to be located in the my-bucket-name-[region_name] with prefix serverless-image-handler/my-version/serverless-image-handler.zip

* Get the link of the serverless-image-handler.template uploaded to your Amazon S3 bucket.
* Deploy the Serverless Image Handler solution to your account by launching a new AWS CloudFormation stack using the link of the serverless-image-handler.template
```bash
https://s3.amazonaws.com/my-bucket-name/serverless-image-handler/my-version/serverless-image-handler.template
```

Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

    http://aws.amazon.com/asl/

or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and limitations under the License.
