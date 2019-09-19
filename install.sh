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
cd $WORKSPACE/$FUNCTIONNAME
npm init -y
npm install --update aws-sam-local
npm install --save-dev typescript
npm install @types/node
alias tsc='"$WORKSPACE"/"$FUNCTIONNAME"/node_modules/typescript/bin/tsc'

cp $CONFIGFOLDER/lambda-config/* $WORKSPACE/$FUNCTIONNAME/
mkdir $WORKSPACE/.vscode
cp $CONFIGFOLDER/vscode-config/* $WORKSPACE/.vscode/
mkdir $WORKSPACE/$FUNCTIONNAME/src
cp $CONFIGFOLDER/lambda-src/index.ts $WORKSPACE/$FUNCTIONNAME/src/
cp $CONFIGFOLDER/lambda-src/event.json $WORKSPACE/$FUNCTIONNAME/src/

cd $WORKSPACE
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -o jq
chmod 755 jq
cd $WORKSPACE/$FUNCTIONNAME

sed "s/function-name/$FUNCTIONNAME/g" template.yaml  > temp_template.yaml
mv temp_template.yaml template.yaml

export nSAM="node_modules/aws-sam-local/node_modules/.bin/sam local invoke -e src/event.json $FUNCTIONNAME"
export nDEBUG="node_modules/aws-sam-local/node_modules/.bin/sam local invoke -e src/event.json --debug-port 9999 $FUNCTIONNAME"

../jq '.scripts = {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "/node_modules/typescript/bin/tsc",
    "sam": env.nSAM,
    "debug": env.nDEBUG
  }' package.json > temp_1212.json

mv temp_1212.json package.json
cp $CONFIGFOLDER/other-config/tslint.json $WORKSPACE/

echo "Removing jq"
rm -rf ../jq

cd $WORKSPACE/.vscode

cat > temp_launch.json << EOF
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

mv temp_launch.json launch.json

## TEST
cd $WORKSPACE/$FUNCTIONNAME
tsc
npm run sam