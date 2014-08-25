echo
echo "================================================================="
echo "===== Installing CoreText ======================================="
echo

if [ $1 = "clean" ] || [ $1 = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/CoreText
fi

make
sudo make install

