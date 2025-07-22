#!/bin/sh

cd $(dirname $0)


echo "Running test script"
/bin/sh finder-test.sh
echo "Running test script second time"
./finder-test.sh
rc=$?
if [ ${rc} -eq 0 ]; then
    echo "Completed with success!!"
else
    echo "Completed with failure, failed with rc=${rc}"
fi
echo "finder-app execution complete, dropping to terminal"
/bin/sh
