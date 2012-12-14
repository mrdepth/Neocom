#/bin/bash

for xib in *.xib
do
#strings=`echo $xib | sed -e "s/~ipad//g"`
strings=`echo $xib | sed -e "s/.xib/.strings/g"`
ibtool --generate-strings-file $strings $xib
done
