#!/usr/bin/env bash

ldd() {
	objdump -p $1 | grep NEEDED | cut -d' ' -f18
}

track_lib() {
	! [ -e "$1" ] && return;
	i=`ldd $1`
	[ $? != 0 ] && return;
	echo $i
	! [ -z "$i" ] && track_lib $PREFIX/lib/$i 
}

if [ $# = 0 ]; then
	echo "Usage: mkpkg <commands>"
else
	cwd=`pwd`
	for cmd in $@; do
		! command -v $cmd > /dev/null && echo "$cmd not found" &&  exit 1
		[ -d $cwd/.tmp/$cmd ] && rm -rf $cwd/.tmp/$cmd
		mkdir -p $cwd/.tmp/$cmd
		cd $cwd/.tmp/$cmd

		clib() {
			echo -n "$1 "
			[ -e $PREFIX/lib64/$1 ] && cp $PREFIX/lib64/$1 lib64
			[ -e $PREFIX/lib/$1 ] && cp $PREFIX/lib/$1 lib
		}

		for i in lib lib64 bin; do
			[ -d $PREFIX/$i ] && mkdir $i
		done

		echo "[$cmd] Fetching Library...."
		for lib in `ldd $(command -v $cmd)`; do
			if [ "$lib" != "libc.so" ]; then
				for i in `track_lib $PREFIX/lib/$lib || track_lib $PREFIX/lib64/$lib`; do
					if [ "$i" != "libc.so" ]; then
						clib $i
					fi
				done
				clib $lib
			fi
		done

		cp $(command -v $cmd) bin

		echo -e "\n[$cmd] Packing & Compressing...."
		tar -cvzf $cwd/$cmd-$(uname -o)-$(uname -m).tgz .
		[ $? = 0 ] && rm -rf $cwd/.tmp/$cmd
	done

	[ $? = 0 ] && rm -rf $cwd/.tmp
fi
