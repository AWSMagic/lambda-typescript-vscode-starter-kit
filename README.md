# Lambda Starter-Kit for TypeScript with Visual Studio Code

Lambda Starter Kit for TypeScript, AWS SAM and VSCode

In order to use Lambda Starter Kit first:

- Install and Run Docker
- Install Node.js
- Install Visual Studio Code

## About Installer

This starter kit has a script named `install.sh` which expects three attributes.

```
-r: root folder
-p: project name
-f: function name
-b: s3 bucket name, you must create this bucket in advance
```

Sample Usage:

```bash
$ ./intsall.sh -r ~/src -p projectOne -f functionOne -b ozlambdabucket
```
