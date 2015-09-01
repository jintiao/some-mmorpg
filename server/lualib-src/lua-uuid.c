#include <lua.h>
#include <lauxlib.h>

static uint32_t sid;

static int
lsid (lua_State *L) {
	if (sid >= 0xffff)
		return 0;
	sid++;
	lua_pushinteger (L, sid);
	return 1;
}

int
luaopen_uuid_core (lua_State *L) {
	luaL_checkversion (L);
	luaL_Reg l[] = {
		{ "sid", lsid },
		{ NULL, NULL },
	};
	luaL_newlib (L,l);
	sid = 0;
	return 1;
}
