# diskperfomancetest

Currently there are two scripts in this system.

## create_files.sh

Random file generator for producing synthetic test data. I recommend running three of these in parallel

```
mkdir /mnt/test/source
./create_files.sh --amount-to-generate 10TB -size-range large --output-path /mnt/test/source
./create_files.sh --amount-to-generate 10TB -size-range medium --output-path /mnt/test/source
./create_files.sh --amount-to-generate 5TB -size-range small --output-path /mnt/test/source
```

## test_copy.py

This tests disk read and write performance by copying random source files to a destination directory and occassionally deleting groups of files to promote extensive fragmentation as well as directory structure stress testing.

```
mkdir /mnt/test/destination
./test_copy.py --source-path /mnt/test/source --destination-path /mnt/test/destination --csv ~/speed_test.csv --max-gb 20000 --thread-count 16
```
