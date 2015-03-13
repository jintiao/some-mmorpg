THIRD_LIB_ROOT ?= ../3rd/

SKYNET_ROOT ?= $(THIRD_LIB_ROOT)skynet/
CJSON_ROOT ?= $(THIRD_LIB_ROOT)lua-cjson
CJSON_INC ?= ../skynet/3rd/lua
OPENSSL_ROOT ?= $(THIRD_LIB_ROOT)openssl
OPENSSL_FLAG ?= -I$(OPENSSL_ROOT)/include -L$(OPENSSL_ROOT) -lcrypto

include $(SKYNET_ROOT)platform.mk

LUA_CLIB_PATH ?= luaclib

SKYNET_BUILD_PATH ?= .

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS) 

# lua

LUA_STATICLIB := $(SKYNET_ROOT)3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= $(SKYNET_ROOT)3rd/lua

# skynet

LUA_CLIB = srp aes cjson

all : $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/srp.so : lualib-src/lua-srp.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ $(OPENSSL_FLAG) -o $@ 

$(LUA_CLIB_PATH)/aes.so : lualib-src/lua-aes.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ $(OPENSSL_FLAG) -o $@ 

$(LUA_CLIB_PATH)/cjson.so : | $(LUA_CLIB_PATH)
	cd $(CJSON_ROOT) && $(MAKE) LUA_INCLUDE_DIR=$(CJSON_INC) CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cd - && cp $(CJSON_ROOT)/cjson.so $@

clean :
	rm -f $(LUA_CLIB_PATH)/*.so

cleanall: clean

