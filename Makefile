MYOS=$(shell uname -s)

all: target/lib/dbgen.jar target/datagenerator-1.0-SNAPSHOT.jar

target/datagenerator-1.0-SNAPSHOT.jar: $(shell find -name *.java)
	mvn package

target/tpch_kit.zip: tpch_kit.zip
	mkdir -p target/
	cp tpch_kit.zip target/tpch_kit.zip

tpch_kit.zip:
	curl -o tpch_kit.zip file:///$(PWD)/src/main/resources/tpch_kit.zip

target/lib/dbgen.jar: target/tools/dbgen
	cd target/; mkdir -p lib/; ( jar cvf lib/dbgen.jar tools/ || gjar cvf lib/dbgen.jar tools/ )

target/tools/dbgen: target/tpch_kit.zip
	test -d target/tools/ || (cd target; unzip tpch_kit.zip -x __MACOSX/; ln -sf $$PWD/*/dbgen/ tools)
	cd target/tools; cat ../../../patches/${MYOS}/*.patch | patch -p0
	cd target/tools; make -f makefile.suite clean; make -f makefile.suite CC=gcc DATABASE=ORACLE MACHINE=LINUX WORKLOAD=TPCH

clean:
	mvn clean
