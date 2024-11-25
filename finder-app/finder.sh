#!/bin/bash 

#first bash script

# Passing the first argument / $1:
FILESDIR=$1
# Passing the second argument / $2:
SEARCHSTR=$2

# if statement with a test command of :  $# -> number of arguments, -lt comparaison with 2
if [ $# -lt 2 ]
then 
	echo "Number of arguments should be equal to 2"
	exit 1
else
	# if statement with a test command of :  ! -> not true, -d "FILESDIR" -> directory with the name "FILESDIR"
	if [ ! -d "$FILESDIR" ]
	then 
		echo "${FILESDIR} does not represent a directory on the file system"
		exit 1
	else
		FILECOUNT=$(find ${FILESDIR} -type f | wc -l)
		cd ${FILESDIR}
		WORDCOUNT=$(grep -r "${SEARCHSTR}" * | wc -l)
		echo "The number of files are ${FILECOUNT} and the number of matching lines are ${WORDCOUNT}"

		#echo "The number of file founds are ${FILECOUNT} and the number of matching are ${WORDCOUNT}"
	fi
fi
		
		
