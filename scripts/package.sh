#!/bin/bash

set -eu

executable=$1
targetExec=.build/lambda/${executable}-exe
targetLibs=.build/lambda/${executable}-libs
targetExecLibs=.build/lambda/${executable} # exe + libs

echo "Cleanup ..."
for d in ${targetExec} ${targetLibs} ${targetExecLibs}; do rm -rf $d; done

echo "Package exe ..."
mkdir -p ${targetExec}
cp -v .build/release/${executable} ${targetExec}/
pushd ${targetExec}
ln -s ${executable} bootstrap
zip --symlinks ../${executable}-exe.zip * */*
popd

libs=`ldd .build/release/${executable} | grep swift | awk '{print $3}'`

echo "Package libs ..."
mkdir -p ${targetLibs}/lib
for l in ${libs}; do cp -Lv $l ${targetLibs}/lib; done
pushd ${targetLibs}
zip --symlinks ../${executable}-libs.zip * */*
popd

echo "Package exe and libs ..."
mkdir -p ${targetExecLibs}
cp -v .build/release/${executable} ${targetExecLibs}/
for l in ${libs}; do cp -Lv $l ${targetExecLibs}; done
pushd ${targetExecLibs}
ln -s ${executable} bootstrap
zip --symlinks ../${executable}.zip * */*
popd
