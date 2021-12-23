#!/usr/bin/env bash

if [ $# = 0 ]; then
	echo "Usage: mkpkg <commands>"
else
	cwd=`pwd`
	for cmd in $@; do
		! command -v $cmd > /dev/null && echo "$cmd not found" &&  exit 1
		[ -d $cwd/.tmp/$cmd ] && rm -rf $cwd/.tmp/$cmd
		mkdir -p $cwd/.tmp/$cmd
		cd $cwd/.tmp/$cmd

		for i in lib lib64 bin; do
			[ -d $PREFIX/$i ] && mkdir $i
		done

		echo "[$cmd] Fetching Library...."
		for lib in `ldd $(command -v $cmd)`; do
			if [ "$lib" != "libc.so" ]; then
				echo -n "$lib "
				[ -e $PREFIX/lib64/$lib ] && cp $PREFIX/lib64/$lib lib64
				[ -e $PREFIX/lib/$lib ] && cp $PREFIX/lib/$lib lib
			fi
		done

		cp $(command -v $cmd) bin

		echo -e "\n[$cmd] Packing & Compressing...."
		tar -cvzf $cwd/$cmd-$(uname -o)-$(uname -m).tgz .
		[ $? = 0 ] && rm -rf $cwd/.tmp/$cmd
	done

	[ $? = 0 ] && rm -rf $cwd/.tmp
fi
