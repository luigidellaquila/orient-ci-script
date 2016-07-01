#!/bin/bash
#
# Copyright (c) OrientDB LTD (http://www.orientdb.com)
#

export ORIENTDB_ROOT_PASSWORD="root"
export SLEEP_TIME=3

# resolve links - $0 may be a softlink
gzFile=$1

# extract dist name
old_IFS=$IFS      # save the field separator           
IFS='/' read -r -a items <<< "$gzFile"
distributionName=""
for element in "${items[@]}"
  do
  distributionName=$element
done
IFS=$old_IFS     # restore default field separator 

distNameLength="${#distributionName}"-7

distributionName=${distributionName:0:$distNameLength}

cd console-routines
export ROUTINES_HOME=$(pwd)
routineTestNames=($(ls -d */))
cd ..

echo -e "\n\n"
echo    "***************************************************"
echo    "Preparing QA Test Environment"
echo    "***************************************************"

#copy and unzip the file
rm -rf test_ce
mkdir test_ce
#echo $gzFile
cp $gzFile test_ce
cd test_ce
export TESTCE_PATH=$(pwd)
tar -xvf $gzFile
rm *.tar.gz
cd $distributionName
export ORIENTDB_HOME=$(pwd)

# Downloading Tolkien-Arda from cloud
cd databases
mkdir Tolkien-Arda
cd Tolkien-Arda
curl -O http://orientdb.com/public-databases/Tolkien-Arda.zip
unzip Tolkien-Arda.zip
rm Tolkien-Arda.zip

echo -e "\n\n"
echo -e "***************************************************\n"
echo -e "INFO\n"
echo    "Distribution:    " $distributionName
echo    "ORIENTDB_HOME:   " $ORIENTDB_HOME
echo    "Test Routines:   " $routineTestNames
echo    "ROUTINES_HOME:   " $ROUTINES_HOME
echo -e "Tests output dir:" $TESTCE_PATH "\n"
echo -e "***************************************************"

echo -e "\n\n"
echo    "***************************************************"
echo -e "Server Startup/Shutdown tests"
echo    "***************************************************"


### TEST SHUTDOWN
cd $ORIENTDB_HOME/bin
./server.sh > $TESTCE_PATH/server.log &
sleep $SLEEP_TIME
shutdownOutput=$(jps | grep OServerMain)
if [ ${#shutdownOutput} -lt "11" ]
then
    echo "FAIL on startup - step 1"
    exit 1;
fi
./shutdown.sh
sleep $SLEEP_TIME
shutdownOutput=$(jps | grep OServerMain)
echo ""
echo "JPS: ${shutdownOutput}"
if [ ${#shutdownOutput} -gt "2" ]
then
    echo "FAIL on shutdown - step 2"
    exit 1;
fi

### TEST SHUTDOWN WITH CREDENTIALS

./server.sh > $TESTCE_PATH/server.log &
sleep $SLEEP_TIME
./shutdown.sh -u root -p root
sleep $SLEEP_TIME
shutdownOutput=$(jps | grep OServerMain)
echo ""
echo "JPS: ${shutdownOutput}"
if [ ${#shutdownOutput} -gt "2" ]
then
    echo "FAIL on shutdown - step 3"
    exit 1;
fi

echo -e "\n\n"
echo    "***************************************************"
echo -e "Executing console-routines tests"
echo    "***************************************************"

old_IFS=$IFS      # save the field separator 
IFS=$'\n'

### TEST CONSOLE SCRIPTS


echo ""
for i in "${routineTestNames[@]}"
do
    # start server
    ./server.sh > $TESTCE_PATH/server.log &
    sleep $SLEEP_TIME

    ilength=${#i}
    ilength=`expr ${ilength} - 1`
    routineName=${i:0:ilength}
    echo "Executing '"$routineName"' routine"
    if [ ${ilength} -gt "1" ]
    then
        mkdir $TESTCE_PATH/${routineName}_result

        # Splitting output-commands.txt
        awk 'BEGIN {RS = "(^|\n)<OUT-COMM-[0-9]*>\n"} ; { if (NR>1) print $0 >> "'$ROUTINES_HOME/$routineName/'expected-command-output-"(NR-1)".txt"}' $ROUTINES_HOME/$routineName/output-commands.txt

	    echo "doing ./console.sh $ROUTINES_HOME/$routineName/input-commands.txt > $TESTCE_PATH/${routineName}_result/console_${routineName}_result.log"
        ./console.sh $ROUTINES_HOME/$routineName/input-commands.txt > $TESTCE_PATH/${routineName}_result/console_${routineName}_result.log
    	
        cat $TESTCE_PATH/${routineName}_result/console_${routineName}_result.log	

        # Splitting console_${routineName}_result.log into 'actual-command-output' files
        sed -e 's/orientdb.*>.*/<OUT-COMM>/' $TESTCE_PATH/${routineName}_result/console_basic_routine_result.log |
          awk 'BEGIN {RS = "(^|\n)<OUT-COMM>\n"} ; { if (NR>1) print $0 >> "'$TESTCE_PATH/${routineName}_result/'actual-command-ouput-"(NR-1)".txt"}'

        #Comparing actual command outputs with the expected command outputs
        
        

        # Removing expected and actual commands' outputs chunks
        #rm $ROUTINES_HOME/$routineName/expected-command-output-*
        #rm $TESTCE_PATH/${routineName}_result/actual-command-ouput-*
    fi

    # shutdown server
    ./shutdown.sh
done


IFS=$old_IFS     # restore default field separator 


echo "********* SUCCESS ************"
exit 0