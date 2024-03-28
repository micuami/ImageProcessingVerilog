#!/bin/bash

if [ "$1" != "nodup" ]; then
    ./clean.sh
fi

mkdir -p ../../build
pushd ../../build > /dev/null

if [ ! -e lib/work ]; then
    echo Compiling common files...
    vlogcomp "$XILINX/verilog/src/glbl.v" -incremental -work work=lib/work > /dev/null
fi

if [ ! -e lib/tester ]; then
    echo Compiling tester...
    for f in ../tester/*.v; do 
        vlogcomp -incremental -work tester=lib/tester "$f" > /dev/null
    done
fi

if [ ! -e lib/reference ]; then
    echo Compiling reference implementation...
    for f in ../reference/*.v; do
        vlogcomp -incremental -work reference=lib/reference "$f" > /dev/null
    done
fi

echo Compiling implementation under test...
for f in ../*.v; do
    vlogcomp -incremental -work uut=lib/uut "$f" > /dev/null
done

popd > /dev/null
