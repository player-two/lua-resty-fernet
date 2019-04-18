#!/bin/sh -e

OPENRESTY_HOME=/usr/local/openresty
SPEC=$(ls *.rockspec)
NAME=resty-fernet-example
PORT=8089

docker run --rm -d --name $NAME \
  -v `pwd`/example/nginx.conf:/nginx.conf \
  -v `pwd`/$SPEC:/$SPEC \
  -v `pwd`/lib/resty/fernet.lua:$OPENRESTY_HOME/luajit/share/lua/5.1/resty/fernet.lua \
  -p $PORT:8080 \
  openresty/openresty:1.13.6.1-1-centos \
  bash -c "luarocks install /$SPEC; openresty -c /nginx.conf -g 'daemon off;'" > /dev/null

echo 'Waiting for nginx to start...'
sleep 5

session=$(curl localhost:$PORT/login -s -i | grep -i 'set-cookie' | sed -e 's/[^:]*: session=\(.*\);/\1/')
echo "Got session: $session"
curl localhost:$PORT -s -b session=$session

docker kill $NAME > /dev/null
