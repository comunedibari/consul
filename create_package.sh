#!/bin/bash

dbPath="db"
appPath="app"
configPath="config"

checkCm () {
    if [ $cmName == "cm1" ] || [ $cmName == "cm2" ]
    then
	true
    else
        echo Errore: $cmName non gestito
	bash create_package.sh
    fi
}

checkPath () {
    if [ -z "$pathName" ]
    then
	pathName="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
        echo $pathName
    else
	echo $pathName
	true
    fi
}

cleanCm () {
    echo
    echo DIRECTORY
    echo DELETED: $pathName/$configPath/custom/$cmName
    rm -rf $pathName/$configPath/custom/$cmName
    echo DELETED: $pathName/$dbPath/$cmName
    rm -rf $pathName/$dbPath/$cmName
    echo DELETED: $pathName/$appPath/assets/images/custom/$cmName
    rm -rf $pathName/$appPath/assets/images/custom/$cmName
    echo DELETED: $pathName/$appPath/views/custom/$cmName
    rm -rf $pathName/$appPath/views/custom/$cmName
    echo DELETED: $pathName/$appPath/views/v2/custom/$cmName
    rm -rf $pathName/$appPath/views/v2/custom/$cmName
    echo DELETED: $pathName/$appPath/controllers/custom/$cmName
    rm -rf $pathName/$appPath/controllers/custom/$cmName
    echo DELETED: $pathName/$appPath/models/custom/$cmName
    rm -rf $pathName/$appPath/models/custom/$cmName
    echo
    echo FILE
    echo DELETED: $pathName/$appPath/assets/stylesheets/$cmName.scss
    rm $pathName/$appPath/assets/stylesheets/$cmName.scss
    echo DELETED: $pathName/$appPath/assets/images/sfondo_$cmName.png
    rm $pathName/$appPath/assets/images/sfondo_$cmName.png
    echo DELETED: $pathName/$dbPath/schema.rb
    rm $pathName/$dbPath/schema.rb
}

echo Quale cm devo pulire?
read cmName
checkCm
echo Ok, pulisco $cmName, su quale path?
read pathName
checkPath
echo Perfetto, inizio la preparazione del pacchetto nella path $pathName, per il $cmName
cleanCm
