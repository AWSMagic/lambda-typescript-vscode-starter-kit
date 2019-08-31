##
# Change these
# vvvvvvvvvvvvvvvvvvvvvvvv
ROOTFOLDER=~/src
PROJECT=project-one
FUNCTIONNAME=function-one
# ^^^^^^^^^^^^^^^^^^^^^^^^

### DONT CHANGE ANYTHING BELOW #####
####################################

CONFIGFOLDER=`pwd`
WORKSPACE=$ROOTFOLDER/$PROJECT

echo $PROJECT
echo $WORKSPACE
echo $FUNCTIONNAME
echo $CONFIGFOLDER

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
../jq '.scripts = {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "tsc",
    "sam": "node_modules/aws-sam-local/node_modules/.bin/sam local invoke -e src/event.json function-one",
    "debug": "node_modules/aws-sam-local/node_modules/.bin/sam local invoke -e src/event.json --debug-port 9999 function-one"
  }' package.json > temp_1212.json

mv temp_1212.json package.json
cp $CONFIGFOLDER/other-config/tslint.json $WORKSPACE/

## TEST
cd $WORKSPACE/$FUNCTIONNAME
tsc
npm run sam