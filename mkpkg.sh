#!/usr/bin/env bash

if [ $# = 0 ]; then
	echo "Usage: mkpkg <command> <target>"
else
	cwd=`pwd`
	mkdir -p $cwd/.tmp/$1
	cd $cwd/.tmp/$1

	for i in lib lib64 bin; do
		[ -d $PREFIX/$i ] && mkdir $i
	done

	for lib in `ldd $(command -v $1)`; do
		[ -e $PREFIX/lib64/$lib ] && cp $PREFIX/lib64/$lib lib64
		[ -e $PREFIX/lib/$lib ] && cp $PREFIX/lib/$lib lib
	done

	cp $(command -v $1) bin
	tar -cWzf $cwd/${2:-$1.tgz} .
	[ $? = 0 ] && rm -rf $cwd/.tmp/$1
fi
