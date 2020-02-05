# Lambda Starter-Kit for TypeScript with Visual Studio Code

Lambda Starter Kit for TypeScript, AWS SAM and VSCode

In order to use Lambda Starter Kit first:

- Install and Run Docker
- Install Node.js
- Install Visual Studio Code
- Create an S3 bucket

## About Installer

This starter kit has a script named `install.sh` which expects three attributes.

```
-r: root folder
-a: application name
-f: function name
-b: s3 bucket name, you must create this bucket in advance
-p: AWS CLI profile name
```

Sample Usage:

```bash
$ ./install.sh -r ~/src -a appOne -f functionOne -b ozlambdabucket -p lambdadev
```
