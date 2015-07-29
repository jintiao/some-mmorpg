
#include <syslog.h>
#include <stdio.h>

#include "skynet.h"

static int
cb (struct skynet_context *ctx, void *ud, int type, int session, uint32_t source, const void *msg, size_t sz) {
	syslog (LOG_ERR, "[:%08x] %s", source, (const char *)msg);
	return 0;
}

int
syslog_init (void *inst, struct skynet_context *ctx, const char *ident) {
	openlog (ident, LOG_PID, LOG_LOCAL3);
	skynet_callback (ctx, NULL, cb);
	skynet_command (ctx, "REG", ".logger");
	return 0;
}

