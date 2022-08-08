#!/bin/bash

help() {
    echo "create_files.sh"
    echo "---------------"
    echo "Create a series of random files with random names in a given output directory"
    echo ""
    echo "Parameters"
    echo "----------"
    echo "--amount-to-generate  The amount of data to generate. This is formatted"
    echo " -a                   as a size such as 10MB. The unit can be KB|MB|GB|TB"
    echo ""
    echo "--size-range          The size range to generate"
    echo " -s                     - small : 4K to 1MB"
    echo "                        - medium : 1M to 1GB"
    echo "                        - large : 1GB to 2TB"
    echo ""
    echo "--output-path         The destination directory to store the generated files"
    echo " -o                   The directory will be created if it does not exist"
    echo ""
    echo "--help                Show this help text"
    echo " -h"
    echo ""
    echo "Examples"
    echo "  Produce 2GB of files from 1M to 1GB in size within /tmp/foo"
    echo "  create_files.sh -a 2GB -s medium -o /tmp/foo"
}

dependenciesOk=1

# Test for hexdump - needed for generating file names
if ! command -v hexdump &> /dev/null
then
    >&2 echo "hexdump is required to run this script. On Ubuntu, install package bsdmainutils"
    dependenciesOk=0
fi

# Test for pv - needed for showing copy progress
if ! command -v pv &> /dev/null
then
    >&2 echo "pv is required to run this script. On Ubuntu, install package pv"
    dependenciesOk=0
fi 

if (( dependenciesOk < 0 ))
then
    exit -1
fi

POSITIONAL_ARGS=()

amountToGenerate=""
sizeRange=""
outputPath=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--amount-to-generate)
      amountToGenerate="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--size-range)
      sizeRange="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output-path)
      outputPath="$2"
      shift # past argument
      shift # past value
      ;;
    -?|--help)
      help

      exit 1
      ;;
    --default)
      DEFAULT=YES
      shift # past argument
      ;;
    -*|--*)
      >&2 echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

if [ -z "$amountToGenerate" ]
then
    >&2 echo "--amount-to-generate parameter is missing"
    exit -1
fi

if [ -z "$sizeRange" ]
then
    >&2 echo "--size-range parameter is missing"
    exit -1
fi

if [ -z "$outputPath" ]
then
    echo "--output-path parameter is missing"
    exit -1
fi

regexSplitSize="([[:digit:]]+)(KB|MB|GB|TB)"

count=0
units=0

if [[ ${amountToGenerate^^} =~ $regexSplitSize ]]
then
    count=${BASH_REMATCH[1]}
    units=${BASH_REMATCH[2]}

    echo $count   $units
else
    >&2 echo "--amount-to-generate= must be formated as size in terms of quantity and units such as 10TB"
    exit -1
fi

kb=$((      1024))
mb=$(($kb * 1024))
gb=$(($mb * 1024))
tb=$(($gb * 1024))

toGenerateUnits=1
if [ $units == KB ]
then
    toGenerateUnits=$kb
fi

if [ $units == MB ]
then
    toGenerateUnits=$mb
fi

if [ $units == GB ]
then
    toGenerateUnits=$gb
fi

if [ $units == TB ]
then
    toGenerateUnits=$tb
fi

outputPath=/dcache/bigdump

sizeToGenerate=${sizeRange^^}
echo $sizeToGenerate

# The script is below

toGenerate=$(($count * $toGenerateUnits))

if [ $sizeToGenerate == SMALL ]
then
    clampLow=$((4 * 1024))
    clampHigh=$((1024 * 1024))
elif [ $sizeToGenerate == MEDIUM ]
then
  clampLow=$((1024 * 1024))
  clampHigh=$((1024 * 1024 * 1024))
elif [ $sizeToGenerate == LARGE ]
then
  clampLow=$((1024 * 1024 * 1024))
  clampHigh=$((2 * 1024 * 1024 * 1024 * 1024))
else
  >&2 echo "--size-range must be small, medium, or large"
  exit -1
fi

generatedTotal=0

outputPath=$(echo $outputPath | sed 's:/*$::')

echo "Creating path $outputPath if it does not exist"
mkdir -p $outputPath

while [ $generatedTotal -lt $toGenerate ]
do
    fileSize=$(shuf -i $clampLow-$clampHigh -n 1)
    fileName=$(hexdump -vn4 -e'"%020X" 1 "\n"' /dev/random)
    outputFilePath="$outputPath/$fileName"
    
    actualSize=$((fileSize / 1024 * 1024))
    
    generatedTotal=$(($generatedTotal + $actualSize))
    generatedPercent=$(($generatedTotal * 100 / $toGenerate))
    
    echo "[$generatedPercent] Generating random file $outputFilePath with the size $fileSize"
    dd if=/dev/urandom bs=$((1024)) count=$(($fileSize / 1024)) status=none | pv | dd of=$outputFilePath status=none
done
