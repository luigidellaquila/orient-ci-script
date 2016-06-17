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
./console.sh ../../../test1.txt > ../../console.log
./shutdown.sh
echo "_______console_log____________"
cat ../../console.log
echo "______ OK! ____________"
exit 0