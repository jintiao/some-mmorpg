
#include <syslog.h>
#include <stdio.h>

#include "skynet.h"


static const char *
check_msg (const char *msg, size_t sz, int *priority) {
	if (sz < 2 || msg[1] != '|')
		return msg;
	switch (msg[0]) {
	case 'D':
		*priority = LOG_DEBUG;
		break;
	case 'I':
		*priority = LOG_INFO;
		break;
	case 'N':
		*priority = LOG_NOTICE;
		break;
	case 'W':
		*priority = LOG_WARNING;
		break;
	case 'E':
		*priority = LOG_ERR;
		break;
	default:
		return msg;
	}
	return &msg[2];
}

static int
cb (struct skynet_context *ctx, void *ud, int type, int session, uint32_t source, const void *msg, size_t sz) {
	int priority = LOG_WARNING;
	const char *str = check_msg ((const char *)msg, sz, &priority);
	syslog (priority, "[:%08x] %s", source, str);
	return 0;
}

int
syslog_init (void *inst, struct skynet_context *ctx, const char *ident) {
	openlog (ident, LOG_PID, LOG_LOCAL3);
	skynet_callback (ctx, NULL, cb);
	skynet_command (ctx, "REG", ".logger");
	return 0;
}

