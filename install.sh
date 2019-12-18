while getopts "r:a:f:b:p:hc:" option 
do
  case "${option}" in
    r) ROOTFOLDER=${OPTARG};;
    a) APPNAME=${OPTARG};;
    f) FUNCTIONNAME=${OPTARG};;
    b) BUCKETNAME=${OPTARG};;
    p) PROFILENAME=${OPTARG};;
    c) CONFIGFOLDER=${OPTARG};;
    h) 
      echo "Usage:"
      echo "$0 -r {root folder} -a {app name} -f {function name} -b {S3 bucket name} -p {aws cli profile name}"
      echo "Example: The command below will create '~/src/project-one/function-one' folder structure"
      echo "$0 -r ~/src -a appOne -f functionOne -b ozlambdabucket -p lambdadev"
      exit 0;;
    \?)
      echo "help: $0 -h"
      exit 1;;
    :)
      echo "Invalid option: $OPTARG requires an argument"
      exit 1;;
  esac
done

if [ -z ${CONFIGFOLDER+x} ];
then
  CONFIGFOLDER=`pwd`;
else
  echo set;
fi

if [[ "$FUNCTIONNAME" =~ [^a-zA-Z0-9] ]]; then
  echo "Lambda Function Name should be alphanumeric."
  echo ""
  exit 1
fi

WORKSPACE=$ROOTFOLDER/$APPNAME
STACKNAME=${FUNCTIONNAME}-stack

echo "Captured these as requirements:"
echo "root folder: $ROOTFOLDER"
echo "application name: $APPNAME"
echo "function name: $FUNCTIONNAME"
echo "S3 bucket name: $BUCKETNAME"
echo "AWS CLI profile name: $PROFILENAME"
echo "workspace folder: $WORKSPACE"
echo "configuration folder (pwd): $CONFIGFOLDER"
echo ""

while true; do
  read -p "Do you want to continue? (y/n) " yn
  case $yn in
      [Yy]* ) break;;
      [Nn]* ) echo "Aborted"; exit;;
      * ) echo "Please answer yes or no.";;
  esac
done

echo "Installing"

mkdir -p $WORKSPACE/$FUNCTIONNAME
cd $WORKSPACE

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install --upgrade awscli
pip install aws-sam-cli
cd $WORKSPACE/$FUNCTIONNAME
npm init -y
npm install --save-dev typescript
npm install @types/node
npm install @types/aws-lambda
alias tsc='"$WORKSPACE"/"$FUNCTIONNAME"/node_modules/typescript/bin/tsc'

mkdir $WORKSPACE/.vscode
cd $WORKSPACE/.vscode

cat > settings.json << EOF
{
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 10000,
  "editor.tabSize": 2,
  "editor.detectIndentation": false,
  "files.exclude": {
    "**/.aws-sam": true,
    "**/*.js": true,
    "**/*.js.map": true,
    "**/node_modules": true,
    "dist": true
  },
  "explorer.autoReveal": true
}
EOF

cat > tasks.json << EOF
{
  "version": "2.0.0",
  "tasks": [
    {
      "type": "npm",
      "script": "build",            
      "path": "$FUNCTIONNAME/",
      "group": "build",
      "problemMatcher": []
    },
    {
      "type": "npm",
      "script": "sam",
      "path": "$FUNCTIONNAME/",
      "problemMatcher": []
    }
  ]
}
EOF

mkdir $WORKSPACE/$FUNCTIONNAME/src
cp $CONFIGFOLDER/lambda-src/index.ts $WORKSPACE/$FUNCTIONNAME/src/
cp $CONFIGFOLDER/lambda-src/event.json $WORKSPACE/$FUNCTIONNAME/src/

cd $WORKSPACE
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -o jq
chmod 755 jq

cd $WORKSPACE/$FUNCTIONNAME

cat > template.yaml << EOF
AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: A starter AWS Lambda function.
Resources:
  $FUNCTIONNAME:
    Type: 'AWS::Serverless::Function'
    Properties:
      Handler: dist/index.handler
      Runtime: nodejs10.x
      CodeUri: .
      Description: A starter AWS Lambda function.
      MemorySize: 128
      Timeout: 3
      Events:
        ${FUNCTIONNAME}Api:
          Type: Api
          Properties:
            Path: /test
            Method: GET      
      Environment:
        Variables:
          Stage: DEV
Outputs:
  ${FUNCTIONNAME}Arn:
    Description: "${FUNCTIONNAME} Lambda Function ARN"
    Value: !GetAtt ${FUNCTIONNAME}.Arn
  ${FUNCTIONNAME}RoleArn:
    Description: "${FUNCTIONNAME} Lambda Function Role"
    Value: !GetAtt ${FUNCTIONNAME}Role.Arn
  ${FUNCTIONNAME}Api:
    Description: "functionOne API ARN"
    Value: !Sub "https://\${ServerlessRestApi}.execute-api.\${AWS::Region}.amazonaws.com/Prod/test/"    
EOF

cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "es2017",
    "module": "commonjs",
    "sourceMap": true,
    "outDir": "./dist",
    "strict": true,
    "typeRoots": [
      "node_modules/@types"
    ],
    "types": [
      "node", "aws-lambda"
    ],
    "esModuleInterop": true
  }
}
EOF

export nINVOKE="source ../.venv/bin/activate; sam local invoke -e src/event.json $FUNCTIONNAME"
export nDEBUG="source ../.venv/bin/activate; sam local invoke -e src/event.json --debug-port 9999 $FUNCTIONNAME"
export nPACKAGE="source ../.venv/bin/activate; sam package --output-template-file packaged.yaml --s3-bucket $BUCKETNAME --profile $PROFILENAME"
export nDEPLOY="source ../.venv/bin/activate; sam deploy --template-file packaged.yaml --region us-east-1 --capabilities CAPABILITY_IAM --stack-name $STACKNAME --profile $PROFILENAME"
export nDELETE="source ../.venv/bin/activate; aws cloudformation delete-stack --stack-name $STACKNAME"

../jq '.scripts = {
    "test": "echo \"Error: no test specified\" && exit 1",
    "transpile": "node_modules/typescript/bin/tsc",
    "build": "npm run transpile; source ../.venv/bin/activate; sam build",
    "invoke": env.nINVOKE,
    "api": "source ../.venv/bin/activate; sam local start-api",
    "debug": env.nDEBUG,
    "package": env.nPACKAGE,
    "deploy": env.nDEPLOY,
    "one-deploy": "npm run build; npm run package; npm run deploy",
    "delete-stack": env.nDELETE
  }' package.json > temp_1212.json

mv temp_1212.json package.json
cp $CONFIGFOLDER/other-config/tslint.json $WORKSPACE/

echo "Removing jq"
rm -rf ../jq

cd $WORKSPACE/.vscode

cat > launch.json << EOF
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Lambda $FUNCTIONNAME",
      "type": "node",
      "request": "attach",
      "sourceMaps": true,
      "address": "localhost",
      "port": 9999,
      "localRoot": "\${workspaceRoot}/$FUNCTIONNAME",
      "remoteRoot": "/var/task",
      "protocol": "inspector",
      "stopOnEntry": false,
      "outFiles": [
        "\${workspaceFolder}/$FUNCTIONNAME/dist/**/*.js"
      ]
    }
  ]
}
EOF

## TEST
cd $WORKSPACE/$FUNCTIONNAME
tsc
npm run build
npm run invoke
