#include <lua.h>
#include <lauxlib.h>
#include <assert.h>
#include <openssl/srp.h>
#include <openssl/rand.h>

#define KEY_SIZE 32 // 32 bytes == 256 bits

static BIGNUM *
random_key () {
	unsigned char tmp[KEY_SIZE];
	RAND_bytes (tmp, sizeof (tmp));
	return BN_bin2bn (tmp, sizeof (tmp), NULL);
}

static void 
push_bn (lua_State *L, BIGNUM *bn) {
	char buf[1024];
	int len = BN_bn2bin (bn, (unsigned char *)buf);
	assert (len < sizeof (buf));
	lua_pushlstring (L, buf, len);
}

static BIGNUM *
lua_tobn (lua_State *L, int index) {
	size_t len = 0;
	const char *s = lua_tolstring (L, index, &len);
	if (s == NULL)
		lua_error (L);
	return BN_bin2bn ((unsigned char *)s, len, NULL);
}
/*
static void
dump (const char *name, BIGNUM *bn) {
	printf ("%s dump\n", name);
	unsigned char buf[1024];
	int len = BN_bn2bin (bn, buf);
	int i = 1;
	for (; i <= len; i++) {
		printf ("%02x", buf[i - 1]);
		if ((i % 16) == 0)
			printf ("\n");
		else if ((i % 8) == 0)
			printf (" - ");
		else
			printf (" ");
	}
	printf ("\n");

}
*/
static int
lcreate_verifier (lua_State *L) {
	SRP_gN *GN = SRP_get_default_gN("1024");
	BIGNUM *s = NULL;
	BIGNUM *v = NULL;

	const char * I = luaL_checkstring (L, 1);
	const char * p = luaL_checkstring (L, 2);

	if (!SRP_create_verifier_BN(I, p, &s, &v, GN->N, GN->g)) {
		return 0;
	}

	push_bn (L, s);
	push_bn (L, v);

	BN_free(s);
	BN_clear_free(v);
	return 2;
}

static int
lcreate_client_key (lua_State *L) {
	SRP_gN *GN = SRP_get_default_gN("1024");
	BIGNUM *a = NULL;
	BIGNUM *A = NULL;

	while (1) {
		a = random_key ();
		A = SRP_Calc_A (a, GN->N, GN->g);

		if (!SRP_Verify_A_mod_N (A, GN->N)) {
			BN_clear_free (a);
			BN_free (A);
		}
		else {
			break;
		}
	}

	push_bn (L, a);
	push_bn (L, A);

	BN_clear_free (a);
	BN_free (A);
	return 2;
}

static int
lcreate_server_session_key (lua_State *L) {
	SRP_gN *GN = SRP_get_default_gN("1024");
	BIGNUM *v = lua_tobn (L, 1);
	BIGNUM *A = lua_tobn (L, 2);

	BIGNUM *b = NULL;
	BIGNUM *B = NULL;

	while (1) {
		b = random_key ();
		B = SRP_Calc_B (b, GN->N, GN->g, v);

		if (!SRP_Verify_B_mod_N (B, GN->N)) {
			BN_clear_free (b);
			BN_free (B);
		}
		else {
			break;
		}
	}

	BIGNUM *u = SRP_Calc_u (A, B, GN->N);
	BIGNUM *K = SRP_Calc_server_key (A, v, u, b, GN->N);

	push_bn (L, K);
	push_bn (L, b);
	push_bn (L, B);

	BN_clear_free (b);
	BN_free (B);
	BN_clear_free (v);
	BN_free (A);
	BN_clear_free (u);
	BN_clear_free (K);
	return 3;
}

static int
lcreate_client_session_key (lua_State *L) {
	SRP_gN *GN = SRP_get_default_gN("1024");
	const char *I = luaL_checkstring (L, 1);
	const char *p = luaL_checkstring (L, 2);
	BIGNUM *s = lua_tobn (L, 3);
	BIGNUM *a = lua_tobn (L, 4);
	BIGNUM *A = lua_tobn (L, 5);
	BIGNUM *B = lua_tobn (L, 6);

	BIGNUM *u = SRP_Calc_u (A, B, GN->N);
	BIGNUM *x = SRP_Calc_x (s, I, p);
	BIGNUM *K = SRP_Calc_client_key (GN->N, B, GN->g, x, a, u);

	push_bn (L, K);

	BN_free (s);
	BN_clear_free (a);
	BN_free (A);
	BN_free (B);
	BN_clear_free (u);
	BN_clear_free (x);
	BN_clear_free (K);
	return 1;
}

static int
lrandom (lua_State *L) {
	BIGNUM *r = random_key ();
	push_bn (L, r);
	BN_free (r);
	return 1;
}

int
luaopen_srp (lua_State *L) {
	luaL_checkversion (L);
	luaL_Reg l[] = {
		{ "create_verifier", lcreate_verifier },
		{ "create_client_key", lcreate_client_key },
		{ "create_server_session_key", lcreate_server_session_key },
		{ "create_client_session_key", lcreate_client_session_key },
		{ "random", lrandom },
		{ NULL, NULL },
	};
	luaL_newlib (L,l);
	return 1;
}
