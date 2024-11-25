#!/bin/bash

WRITEFILE=$1
WRITESTR=$2

if [ $# -lt 2 ]
then
	echo "The arguemnts are not specified as they should"
	exit 1
fi

WRITEDIR=$(dirname $WRITEFILE)

mkdir -p $WRITEDIR  # -p ensure no error already exist

if [ $? -ne 0 ] # $? stores the exit status of the last commannd
then 
	echo "Directory could not be created"
	exit 1

fi

touch $WRITEFILE
 
if [ $? -eq 0 ] && [ -w $WRITEFILE ]
then 
	echo "$WRITESTR" > $WRITEFILE
	
else 
	echo "error in the creation of : ${WRITEFILE}"
	exit 1
fi
	
