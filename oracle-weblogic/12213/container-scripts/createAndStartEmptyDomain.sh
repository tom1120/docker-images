#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

# define configfile env from wisecloud ui

#Define DOMAIN_HOME
export DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME
echo "Domain Home is: " $DOMAIN_HOME

# If AdminServer.log does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer
# Otherwise, only start NM (container restarted)
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${DOMAIN_HOME}/bin/stopWebLogic.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

ADD_DOMAIN=1
if [ ! -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log ]; then
    ADD_DOMAIN=0
fi

mkdir -p $ORACLE_HOME/properties
source $CONFIG_FILE
# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ]; then
   PROPERTIES_FILE=/u01/oracle/properties/domain.properties
   if [ ! -e "$PROPERTIES_FILE" ]; then
      echo "A properties file with the username and password needs to be supplied."
      exit
   fi

   # Get Username
   USER=`awk '{print $1}' $PROPERTIES_FILE | grep username | cut -d "=" -f2`
   if [ -z "$USER" ]; then
      echo "The domain username is blank.  The Admin username must be set in the properties file."
      exit
   fi
   # Get Password
   PASS=`awk '{print $1}' $PROPERTIES_FILE | grep password | cut -d "=" -f2`
   if [ -z "$PASS" ]; then
      echo "The domain password is blank.  The Admin password must be set in the properties file."
      exit
   fi

   # Create an empty domain
   wlst.sh -skipWLSModuleScanning -loadProperties $PROPERTIES_FILE  /u01/oracle/create-wls-domain.py
   mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/
   echo "username=${USER}" >> $DOMAIN_HOME/servers/AdminServer/security/boot.properties
   echo "password=${PASS}" >> $DOMAIN_HOME/servers/AdminServer/security/boot.properties
   ${DOMAIN_HOME}/bin/setDomainEnv.sh
fi

# create datasource
CONFIG_PATH=$(dirname "$CONFIG_FILE")
DATASOURCE_PATH=$CONFIG_PATH/datasource/
if [ -d "$DATASOURCE_PATH" ]
then
  for properties in $(ls $DATASOURCE_PATH)
  do
     wlst.sh -loadProperties $DATASOURCE_PATH$properties /u01/oracle/ds-deploy.py
     echo "create datasource $properties success!"
  done
else
  echo "No datasource.properties file provided,skip to create datasource!"
fi

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh
touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log &

childPID=$!
wait $childPID