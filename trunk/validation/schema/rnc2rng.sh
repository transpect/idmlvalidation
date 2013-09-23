#!/bin/bash
mkdir -p rng/$1/MasterSpreads
mkdir -p rng/$1/Spreads
mkdir -p rng/$1/Resources
mkdir -p rng/$1/Stories
mkdir -p rng/$1/XML
for rncfile in rnc/$1/MasterSpreads/*; do \
    java -jar /data/develop/pglatza/trang-20091111/trang.jar $rncfile rng/$1/MasterSpreads/`basename ${rncfile} .rnc`.rng ; \
    sed -i '/datatype.rng/c\  <include href="..\/datatype.rng"\/>' rng/$1/MasterSpreads/`basename ${rncfile} .rnc`.rng
done
for rncfile in rnc/$1/Spreads/*; do \
    java -jar /data/develop/pglatza/trang-20091111/trang.jar $rncfile rng/$1/Spreads/`basename ${rncfile} .rnc`.rng ; \
    sed -i '/datatype.rng/c\  <include href="..\/datatype.rng"\/>' rng/$1/Spreads/`basename ${rncfile} .rnc`.rng
done
for rncfile in rnc/$1/Stories/*; do \
    java -jar /data/develop/pglatza/trang-20091111/trang.jar $rncfile rng/$1/Stories/`basename ${rncfile} .rnc`.rng ; \
    sed -i '/datatype.rng/c\  <include href="..\/datatype.rng"\/>' rng/$1/Stories/`basename ${rncfile} .rnc`.rng
done
for rncfile in rnc/$1/XML/*; do \
    java -jar /data/develop/pglatza/trang-20091111/trang.jar $rncfile rng/$1/XML/`basename ${rncfile} .rnc`.rng ; \
    sed -i '/datatype.rng/c\  <include href="..\/datatype.rng"\/>' rng/$1/XML/`basename ${rncfile} .rnc`.rng
done
for rncfile in rnc/$1/Resources/*; do \
    java -jar /data/develop/pglatza/trang-20091111/trang.jar $rncfile rng/$1/Resources/`basename ${rncfile} .rnc`.rng ; \
    sed -i '/datatype.rng/c\  <include href="..\/datatype.rng"\/>' rng/$1/Resources/`basename ${rncfile} .rnc`.rng
done
rm rng/$1/*/datatype.rng
