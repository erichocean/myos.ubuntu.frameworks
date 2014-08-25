
source ../common-install.sh

echo
echo "================================================================="
echo "===== Installing CoreFoundation ================================="
echo

if [ ${SCHEME} = "full" ] ; then
    sudo aptitude -y install libicu-dev libproc-dev 
#libprocps0-dev
#fi
#if [ $1 = "clean" ] || [ $1 = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/CoreFoundation
fi

make
sudo make install

