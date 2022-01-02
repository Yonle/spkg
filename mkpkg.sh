#!/usr/bin/env sh

ldd() {
	r=`readelf -d $1 | grep -o "\[.*\.so.*]" | sed "s/\[//g" | sed "s/\]//g"`
	[ "$r" != "$1" ] && echo $r
}

track_lib() {
	! [ -e "$1" ] || [ "$1" = "$2" ] && return;
	i=`ldd $1`
	[ $? != 0 ] && return;
	echo $i
	! [ -z "$i" ] && track_lib $PREFIX/lib/$i $1
}

if [ $# = 0 ]; then
	echo "Usage: mkpkg <commands>"
else
	cwd=`pwd`
	for cmd in $@; do
		! command -v $cmd > /dev/null && echo "$cmd not found" &&  exit 1
		[ -d $cwd/.tmp/$cmd ] && rm -rf $cwd/.tmp/$cmd
		mkdir -p $cwd/.tmp/$cmd
		[ $? != 0 ] && exec echo "I can't create package file on this directory."
		cd $cwd/.tmp/$cmd

		clib() {
			[ -e lib/$1 ] || [ -e lib64/$1 ] && return;
			echo -n "$1 "
			[ -e $PREFIX/lib64/$1 ] && cp $PREFIX/lib64/$1 lib64
			[ -e $PREFIX/lib/$1 ] && cp $PREFIX/lib/$1 lib
			[ -e /lib/$1 ] && cp /lib/$1 lib
			[ -e /lib64/$1 ] && cp /lib64/$1 lib64
			[ -e $PREFIX/local/lib/$1 ] && cp $PREFIX/local/lib/$1 lib
			[ -e $PREFIX/local/lib64/$1 ] && cp $PREFIX/local/lib64/$1 lib64
			#[ -e /system/lib/$1 ] && cp /system/lib/$1 lib
			#[ -e /system/lib64/$1 ] && cp /system/lib64/$1 lib64
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
		tar -cvzf $cwd/$cmd-$(uname)-$(uname -m).tgz .
		[ $? = 0 ] && rm -rf $cwd/.tmp/$cmd
	done

	[ $? = 0 ] && rm -rf $cwd/.tmp
fi
