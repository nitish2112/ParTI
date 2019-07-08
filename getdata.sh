#!/bin/bash

set -x


# NELL-2

wget https://s3.us-east-2.amazonaws.com/frostt/frostt_data/nell/nell-2.tns.gz &&
gunzip nell-2.tns.gz &&
rm -rf nell-2.tns.gz &&
echo "3" > nell-2-parti.tns &&
echo "12092 9184 28818" >> nell-2-parti.tns &&
cat nell-2.tns >> nell-2-parti.tns &&

# Netflix

echo "3" > netflix-parti.tns &&
echo "480189 17770 2182" >> netflix-parti.tns &&
cat netflix.tns >> netflix-parti.tns &&

# Poisson3D

git clone https://github.coecis.cornell.edu/nks45/poisson3D.git
bzip2 -dk poisson3D/poisson3D.tns.bz2
mv poisson3D/poisson3D.tns .
rm -rf poisson3D
echo "3" > poisson3D-parti.tns &&
echo "3000 3000 3000" >> poisson3D-parti.tns &&
cat poisson3D.tns >> poisson3D-parti.tns &&

# Yahoo

git clone https://github.coecis.cornell.edu/nks45/ml20m.git
bzip2 -dk ml20m/ml20m.tns.bz2
mv ml20m/ml20m.tns .
rm -rf ml20m
echo "3" > ml20m-parti.tns &&
echo "138493 26744 234" >> ml20m-parti.tns &&
cat ml20m.tns >> ml20m-parti.tns
