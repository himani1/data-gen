#!/bin/bash

function usage {
	echo "Usage: tpch-setup.sh scale_factor [temp_directory]"
	exit 1
}

function runcommand {
	if [ "X$DEBUG_SCRIPT" != "X" ]; then
		$1
	else
		$1 2>/dev/null
	fi
}

which hdfs > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Script must be run where HDFS is installed"
	exit 1
fi

if [ ! -f target/datagenerator-1.0-SNAPSHOT.jar ]; then
	echo "Please build the data generator with ./tpch-build.sh first"
	exit 1
fi

# Tables in the TPC-H schema.
TABLES="part partsupp supplier customer orders lineitem nation region"

# Get the parameters.
SCALE=$1
DIR=$2
BUCKETS=13
if [ "X$DEBUG_SCRIPT" != "X" ]; then
	set -x
fi

# Sanity checking.
if [ X"$SCALE" = "X" ]; then
	usage
fi
if [ X"$DIR" = "X" ]; then
	DIR=/tmp/tpch-generate
fi
if [ $SCALE -eq 1 ]; then
	echo "Scale factor must be greater than 1"
	exit 1
fi

# Do the actual data load.
hdfs dfs -mkdir -p ${DIR}
hdfs dfs -ls ${DIR}/${SCALE}/lineitem > /dev/null
if [ $? -ne 0 ]; then
	echo "Generating data at scale factor $SCALE."
	(hadoop jar target/*.jar -d ${DIR}/${SCALE}/ -s ${SCALE})
	(echo "$(hadoop fs -text ${DIR}/${SCALE}/customer/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/customer.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/part/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/part.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/partsupp/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/partsupp.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/region/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/region.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/supplier/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/supplier.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/orders/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/orders.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/lineitem/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/lineitem.csv)
    (echo "$(hadoop fs -text ${DIR}/${SCALE}/nation/*)" |hadoop dfs -put - /tmp/tpch-generate/${SCALE}/nation.csv)
fi
hdfs dfs -ls ${DIR}/${SCALE}/lineitem > /dev/null
if [ $? -ne 0 ]; then
	echo "Data generation failed, exiting."
	exit 1
fi
echo "TPC-H text data generation complete."
