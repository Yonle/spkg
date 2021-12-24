#!/usr/bin/env sh
[ $# = 0 ] && exec echo "Usage: spkg <pkgfile>"
tar -C $PREFIX -xvkzf $*


