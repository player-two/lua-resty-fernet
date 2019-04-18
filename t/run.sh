#!/bin/sh

OPENRESTY_HOME=/usr/local/openresty
SPEC=$(ls *.rockspec)

docker run --rm -it \
  -v `pwd`/$SPEC:/$SPEC \
  -v `pwd`/lib/resty/fernet.lua:$OPENRESTY_HOME/luajit/share/lua/5.1/resty/fernet.lua \
  -v `pwd`/t:/t \
  openresty/openresty:1.13.6.1-1-centos \
  bash -c "luarocks install /$SPEC; cd /t && resty test.lua"
