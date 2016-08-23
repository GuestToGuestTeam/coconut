#!/bin/bash
#
# Makak is the genius script used to open the coconut install archive

COCONUT_BASE_PATH="/var/app"
AWS_REGION="eu-central-1"
COCONUT_VERSION_FILE="/var/app/coco.version"

function autosource {
    COCO_SOURCE_PATH="$COCONUT_CURRENT_APP_PATH/.coconut/$1"
    if [ -d "$COCO_SOURCE_PATH" ]; then
        EXECUTE_DIR=$COCO_SOURCE_PATH/*
        for f in $EXECUTE_DIR
        do
            echo "PROCESSING $f FILE..."
            source $f
        done
    fi
}

echo "GET $COCONUT_BOOTSTRAP FILE"
aws --region="$AWS_REGION" s3 cp $COCONUT_BOOTSTRAP $COCONUT_BASE_PATH/config.json 

if [ -f "$COCONUT_VERSION_FILE" ]
then
    DEPLOYED_VERSION=$(cat $COCONUT_VERSION_FILE)
else
    DEPLOYED_VERSION="0000000000000000"
fi

if [ -f "$COCONUT_BASE_PATH/config.json" ]
then
    COCO_VERSION=$(cat $COCONUT_BASE_PATH/config.json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["deployed"]')
    COCO_PATH=$(cat $COCONUT_BASE_PATH/config.json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["s3"]')
    COCONUT_ENV=$(cat $COCONUT_BASE_PATH/config.json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["env"]')

    if [ "$COCO_VERSION" != "$DEPLOYED_VERSION" ]
    then
        COCONUT_CURRENT_APP_PATH="$COCONUT_BASE_PATH/$COCO_VERSION"

        echo "DEPLOY NEW APPLICATION VERSION: $COCO_VERSION (OLD VERSION: $DEPLOYED_VERSION)"
        aws --region="$AWS_REGION" s3 cp "$COCO_PATH/$COCO_VERSION.zip" "$COCONUT_BASE_PATH/"

        cd $COCONUT_BASE_PATH && unzip -o -d $COCO_VERSION $COCO_VERSION.zip && cd $COCO_VERSION
        
        autosource "pre_install"

        ln -s -f $COCONUT_CURRENT_APP_PATH $COCONUT_BASE_PATH/current
    
        autosource "post_install"

        echo $COCO_VERSION > $COCONUT_VERSION_FILE
        rm -f $COCONUT_BASE_PATH/$COCO_VERSION.zip
    fi
fi
