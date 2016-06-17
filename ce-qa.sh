#!/bin/sh
#
# Copyright (c) OrientDB LTD (http://www.orientdb.com)
#

export ORIENTDB_ROOT_PASSWORD="root"

# resolve links - $0 may be a softlink
gzFile=$1

# extract dist name
IFS='/' read -r -a items <<< "$gzFile"
distName=""
for element in "${items[@]}"
  do
  distName=$element
done

distNameLength="${#distName}"-7

distName=${distName:0:$distNameLength}

cd consoletests
consoleTestNames=($(ls -d */))
echo $consoleTestNames
cd ..

#copy and unzip the file
rm -rf test_ce
mkdir test_ce
#echo $gzFile
cp $gzFile test_ce
cd test_ce
tar -xvf $gzFile
cd $distName
cd bin
./server.sh > ../../server.log &
sleep 10

echo ""
echo $consoleTestNames
for i in "${consoleTestNames[@]}"
do
    ilength=${#i}
    ilength=`expr ${ilength} - 1`
    echo ""
    echo "final length: ${ilength}"
    if [ ${ilength} -gt "1" ]
    then
		echo "doing ${i}"
	    i=${i:0:$ilength}
    	echo "doing ./console.sh ../../../consoletests/$i/test.txt > ../../console_${i}_result.log"
	    ./console.sh ../../../consoletests/$i/test.txt > ../../console_${i}_result.log
    	cat ../../console_${i}_result.log	
    fi
done

./shutdown.sh

echo "______ OK! ____________"
exit 0