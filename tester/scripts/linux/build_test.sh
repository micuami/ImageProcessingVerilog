#!/bin/bash

nodup=

if [ "$2" == "nodup" ]; then
    nodup="nodup"
fi
if [ "$3" == "nodup" ]; then
    nodup="nodup"
fi

build_mode="./build_base.sh $nodup"

if [ "$2" == "nobase" ]; then
    build_mode=
fi
if [ "$3" == "nobase" ]; then
    build_mode=
fi

$build_mode

mkdir -p ../../build
pushd ../../build > /dev/null

if [ ! -e lib/tests/$1 ]; then
    echo Compiling test $1...
    for f in ../tests/$1/*.v; do
        vlogcomp -incremental -work test=lib/tests/$1 $f > /dev/null
    done
fi

popd > /dev/null

echo Linking test $1...

mkdir -p ../../build/bin/$1
pushd ../../build/bin/$1 > /dev/null

fuse -incremental test.test_$1 -L unisims_ver -L unimacro_ver -L xilinxcorelib_ver -L tester=../../lib/tester -L test=../../lib/tests/$1 -L reference=../../lib/reference -L uut=../../lib/uut -o tester.exe > /dev/null

popd > /dev/null
