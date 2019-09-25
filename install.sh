while getopts "r:p:f:hc:" option 
do
  case "${option}" in
    r) ROOTFOLDER=${OPTARG};;
    p) PROJECTNAME=${OPTARG};;
    f) FUNCTIONNAME=${OPTARG};;
    c) CONFIGFOLDER=${OPTARG};;
    h) 
      echo "Usage:"
      echo "$0 -r {root folder} -p {project name} -f {function name}"
      echo "Example: The command below will create '~/src/project-one/function-one' folder structure"
      echo "$0 -r ~/src -p project-one -f function-one"
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

WORKSPACE=$ROOTFOLDER/$PROJECTNAME

echo "Captured these as requirements:"
echo "root folder: $ROOTFOLDER"
echo "project name: $PROJECTNAME"
echo "function name: $FUNCTIONNAME"
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

export nBUILD="npm run transpile; source ../.venv/bin/activate; sam build"
export nINVOKE="source ../.venv/bin/activate; sam local invoke -e src/event.json $FUNCTIONNAME"
export nAPI="source ../.venv/bin/activate; sam local start-api"
export nDEBUG="source ../.venv/bin/activate; sam local invoke -e src/event.json --debug-port 9999 $FUNCTIONNAME"

../jq '.scripts = {
    "test": "echo \"Error: no test specified\" && exit 1",
    "transpile": "node_modules/typescript/bin/tsc",
    "build": env.nBUILD,
    "invoke": env.nINVOKE,
    "start-api": env.nAPI,
    "debug": env.nDEBUG
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