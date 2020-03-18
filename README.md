# Lambda Starter Kit for TypeScript

Lambda Starter Kit for TypeScript, AWS SAM and VSCode


__Requirements__

In order to use Lambda Starter Kit first:

- Install and Run Docker
- Install Node.js
- Install Visual Studio Code
- Create an S3 bucket

You need an S3 bucket which can be used to hold your build artifacts as part of the SAM deployment.

Note! Bucket names are globally unique, so be creative.

```bash
aws s3 mb s3://ozlambdabucket
```

__Usage__

This starter kit has a script named `install-<platform>.sh` which expects several argument:

```
-r: root folder
-a: application name
-f: function name
-b: s3 bucket name, you must create this bucket in advance
-p: AWS CLI profile name
```

__Example__

```bash
$ ./install.sh -r ~/src -a appOne -f functionOne -b ozlambdabucket -p lambdadev
```
