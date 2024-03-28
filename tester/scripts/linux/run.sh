#!/bin/bash

run_mode=

if [ "$1" == "gui" ]; then
     run_mode="gui"
fi
if [ "$2" == "gui" ]; then
     run_mode="gui"
fi

build_mode="./build.sh"

if [ "$1" == "nobuild" ]; then
     build_mode=
fi
if [ "$2" == "nobuild" ]; then
     build_mode=
fi

$build_mode

rm ../../scripts/../results.txt 2> /dev/null
rm ../../scripts/../results.log 2> /dev/null

for d in ../../tests/*; do
    test=`basename $d`
    test_prefix=${test:-1}
    
    ./run_test.sh $test $run_mode nobuild
    
    if [ ! -e ../../run/$test/tester.result ]; then
        if [ "$test_prefix" == "image" ]; then
            echo -3.00: failed to run test $test, check compilation and execution logs >> ../../results.txt
        elif [ "$test" == "lena" ]; then
            echo -1.00: failed to run test $test, check compilation and execution logs >> ../../results.txt
        else
            echo  0.00: failed to run unknown test $test >> ../../results.txt
        fi
    else
        cat ../../run/$test/tester.result >> ../../results.txt
    fi
    cat ../../run/$test/tester.log >> ../../results.log
done

cat ../../results.log
echo --------------------------------------------------------------------------------
cat ../../results.txt
