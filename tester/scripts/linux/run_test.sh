#!/bin/bash

run_mode="../../../scripts/console.tcl"

if [ "$2" == "gui" ]; then
	run_mode="../../../scripts/gui.tcl -gui"
fi
if [ "$3" == "gui" ]; then
	run_mode="../../../scripts/gui.tcl -gui"
fi

build_mode="./build_test.sh $1"

if [ "$2" == "nobuild" ]; then
	build_mode=
fi
if [ "$3" == "nobuild" ]; then
	build_mode=
fi

$build_mode

echo Running test $1...

rm -rf ../../scripts/../run/$1 2> /dev/null

mkdir -p ../../run/$1

mkdir -p ../../build/bin/$1
pushd ../../build/bin/$1 > /dev/null

cp ../../../tests/$1/* .

echo "********************************************************************************" > ../../../run/$1/tester.log
echo "**** Running test $1..." >> ../../../run/$1/tester.log
echo "********************************************************************************" >> ../../../run/$1/tester.log
./tester -intstyle ise -tclbatch $run_mode >> ../../../run/$1/tester.log

mv result.tester ../../../run/$1/tester.result 2> /dev/null

popd > /dev/null
