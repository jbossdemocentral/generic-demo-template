#!/bin/bash

#########################################
##                                     ##
## Creates Demo Project Automagically! ##
##                                     ##
#########################################

# no args need to show help.
if [ $# -ne 1 ]
then
	echo Usage: 
	echo
	echo "     `basename $0` projectname"
	echo
	exit 
fi

# create project directory.
echo
echo Created project directory.
mkdir $1
cd $1

echo 
echo Adding main readme file.

echo "JBoss $1 Quickstart Guide
============================================================

Demo based on JBoss [product-name] products.

Setup and Configuration
-----------------------

See Quick Start Guide in project as ODT and PDF for details on installation.

For those that can't wait, see README in 'installs' directory, add products, 
	run 'init.sh', read output and then read Quick Start Guide that shows you 
	how to demo.

[insert-quickstart-steps]

Released versions
-----------------

See the tagged releases for the following versions of the product:
" > README.md

# create dirs.
echo
echo Creating installs directory and readme.
mkdir installs 
echo "Download the following from the JBoss Customer Portal

* [insert-product] ([insert-product-file].zip)

and copy to this directory for the init.sh script to work.

Ensure that this file is executable by running:

chmod +x <path-to-project>/installs/[insert-product-file].zip
" > installs/README

echo
echo Creating projects directory and readme.
mkdir projects
echo "Directory to hold project." > projects/README

echo
echo Creating support files directory and readme.
mkdir support
echo "Directory to hold helper files." > support/README

echo 
echo Creating various .gitignores.
echo "target/
.DS_Store" > .gitignore
echo ".zip" > installs/.gitignore
echo ".metadata" > projects/.gitignore

echo 
echo Create init.sh for demo, named example_init.sh.
echo '#!/bin/sh 
DEMO="[insert-name] Demo"
JBOSS_HOME=./target/jboss-eap-6.0
SERVER_DIR=$JBOSS_HOME/standalone/deployments/
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
LIB_DIR=./support/lib
SRC_DIR=./installs
EAP=jboss-eap-6.0.1.zip
BRMS=brms-p-5.3.1.GA-deployable-ee6.zip
EAP_REPO=jboss-eap-6.0.1-maven-repository
VERSION=5.3.1


echo
echo "Setting up the JBoss Enterprise EAP 6 ${DEMO} environment..."
echo

# make some checks first before proceeding.	
if [[ -r $SRC_DIR/$EAP || -L $SRC_DIR/$EAP ]]; then
		echo EAP sources are present...
		echo
else
		echo Need to download $EAP package from the Customer Support Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Create the target directory if it does not already exist.
if [ ! -x target ]; then
		echo "  - creating the target directory..."
		echo
		mkdir target
else
		echo "  - detected target directory, moving on..."
		echo
fi

# Move the old JBoss instance, if it exists, to the OLD position.
if [ -x $JBOSS_HOME ]; then
		echo "  - existing JBoss Enterprise EAP 6 detected..."
		echo
		echo "  - moving existing JBoss Enterprise EAP 6 aside..."
		echo
		rm -rf $JBOSS_HOME.OLD
		mv $JBOSS_HOME $JBOSS_HOME.OLD

		# Unzip the JBoss EAP instance.
		echo Unpacking JBoss Enterprise EAP 6...
		echo
		unzip -q -d target $SRC_DIR/$EAP
else
		# Unzip the JBoss EAP instance.
		echo Unpacking new JBoss Enterprise EAP 6...
		echo
		unzip -q -d target $SRC_DIR/$EAP
fi

# Unzip the required files from JBoss BRMS Deployable
echo Unpacking JBoss Enterprise BRMS $VERSION...
echo
cd installs
unzip -q $BRMS

echo "  - deploying JBoss Enterprise BRMS Manager WAR..."
echo
unzip -q -d ../$SERVER_DIR jboss-brms-manager-ee6.zip
rm jboss-brms-manager-ee6.zip 

echo "  - deploying jBPM Console WARs..."
echo
unzip -q -d ../$SERVER_DIR jboss-jbpm-console-ee6.zip
rm jboss-jbpm-console-ee6.zip

unzip -q jboss-jbpm-engine.zip 
echo "  - copying jBPM client JARs..."
echo
unzip -q -d ../$SERVER_DIR jboss-jbpm-engine.zip lib/netty.jar
cp -r lib ../$LIB_DIR
cp jbpm-test-5.3.1.BRMS.jar ../$LIB_DIR
cp jbpm-human-task-5.3.1.BRMS.jar ../$LIB_DIR
cp jbpm-persistence-jpa-5.3.1.BRMS.jar ../$LIB_DIR
cp jbpm-workitems-5.3.1.BRMS.jar ../$LIB_DIR
rm jboss-jbpm-engine.zip
rm -rf *.jar modeshape.zip *.RSA lib
rm jboss-brms-engine.zip

echo Rounding up, setting permissions and copying support files...
echo
cd ../

echo "  - enabling demo accounts logins in brms-users.properties file..."
echo
cp support/brms-users.properties $SERVER_CONF

echo "  - enabling demo accounts role setup in brms-roles.properties file..."
echo
cp support/brms-roles.properties $SERVER_CONF

echo "  - adding dodeploy files to deploy all brms components..."
echo 
touch $SERVER_DIR/business-central-server.war.dodeploy
touch $SERVER_DIR/business-central.war.dodeploy
touch $SERVER_DIR/designer.war.dodeploy
touch $SERVER_DIR/jboss-brms.war.dodeploy
touch $SERVER_DIR/jbpm-human-task.war.dodeploy

echo "  - configuring security authentication, copying updated components.xml file to jboss-brms.war..."
echo
cp support/components.xml $SERVER_DIR/jboss-brms.war/WEB-INF/

echo "  - configuring deployment timeout extention and added security domain brms in standalone.xml..."
echo
cp support/standalone.xml $SERVER_CONF

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

echo "  - enabling demo users for human tasks in jbpm-human-task.war web.xml file..."
echo
cp support/jbpm-human-task-war-web.xml $SERVER_DIR/jbpm-human-task.war/WEB-INF/web.xml

echo "  - enabling work items by registering Email and Log nodes..."
echo
cp support/drools.session.conf $SERVER_DIR/business-central-server.war/WEB-INF/classes/META-INF
cp support/CustomWorkItemHandlers.conf $SERVER_DIR/business-central-server.war/WEB-INF/classes/META-INF
chmod 644 $SERVER_DIR/business-central-server.war/WEB-INF/classes/META-INF/drools.session.conf
chmod 644 $SERVER_DIR/business-central-server.war/WEB-INF/classes/META-INF/CustomWorkItemHandlers.conf

echo "  - adding model jar to business central admin console classpath..." 
echo
cp support/customereval-model.jar $SERVER_DIR/business-central-server.war/WEB-INF/lib

echo "  - adding netty dep to business-central-server.war and jbpm-human-task.war..."
echo
cp support/MANIFEST.MF $SERVER_DIR/business-central-server.war/WEB-INF/classes/META-INF/
cp support/MANIFEST.MF $SERVER_DIR/jbpm-human-task.war/WEB-INF/classes/META-INF/

echo "JBoss Enterprise BRMS ${VERSION} ${DEMO} Setup Complete."
echo' > example_init.sh

echo
echo You can new view your project directory setup in $1.
echo
