lua-resty-fernet
====

A Lua implementation of [Fernet](https://cryptography.io/en/latest/fernet/), used for symmetric cryptography

Table of Contents
=================

* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Methods](#methods)
  - [new](#new)
  - [generate_key](#generate_key)
  - [encrypt](#encrypt)
  - [decrypt](#decrypt)
* [Testing](#testing)

Status
======

This library is considered production ready.

Description
===========

Symmetric encryption uses a shared secret key to encrypt and decrypt sensitive data.  This library can be used to securely send such data in transit or store it at rest.  Since this is built for the [OpenResty](https://openresty.org/en/) web platform, storage may likely be a browser or database.

This is not a general purpose encryption library; it only supports the Fernet specification, which was developed for Python's Cryptography package.  Quoting their docs:

> Fernet is ideal for encrypting data that easily fits in memory. As a design feature it does not expose unauthenticated bytes. Unfortunately, this makes it generally unsuitable for very large files at this time.

- https://cryptography.io/en/latest/fernet/#limitations


Synopsis
========

```lua
local fernet = require "resty.fernet"
local key = fernet:generate_key()
local f = fernet:new(key)
local token, err = f:encrypt("secret")
print(token)
local secret, err = f:decrypt(token)
print(secret)
```

Also see the working [example](./example/nginx.conf) for usage in the context of the OpenResty Lua directives.
```sh
# Expects Docker to be installed and running
./example/run.sh
```


Methods
=======

new
---
`f = fernet:new(key)`

Create an instances that stores the key for use during encryption and decryption.

generate_key
------------
`key = fernet:generate_key()`

Generates a random sequence of bytes (url-safe base64 encoded) that can be passed to [`new`](#new).  This should only be called by your application whose data does not exist beyond the process lifetime.  Under normal circumstances, the key should be generated and stored safely, then passed to the application as configuration.  This can be done via the `resty` CLI:

```sh
resty -e 'print(require("resty.fernet"):generate_key())'
```

encrypt
-------
`token, err = f:encrypt(secret)`

This method _should_ only fail if the `secret` is not a string, and any other failures are either a bug in this library or an issue with a dependency that provides cryptographic primitives.

decrypt
-------
`secret, err = f:decrypt(token, ttl?)`

The `ttl` field can be an integer representing the number of seconds that a token can be valid beyond the time it was created.  If the token is older than the ttl, this function will return `nil` and an error string indicating as much.


Testing
=======

The tests merely run through the scenarios provided in the [Fernet spec](https://github.com/fernet/spec) repository.

```sh
git clone https://github.com/fernet/spec t/spec
./t/run.sh
```

Most of the test cases require manual review - the error message should relate to the test description.
