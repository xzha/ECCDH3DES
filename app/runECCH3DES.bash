#! /bin/bash

#./drivers/load_terasic_qsys_pcie_driver.sh
make clean
make

./app 


python new_des.py input1.txt -t pythonOutput.txt -h -e key.txt output1.txt -h

#scp output1.txt root@ee215de6.ecn.purdue.edu 


exit 0
