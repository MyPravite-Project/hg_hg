/*
 * A fast client for Mercurial command server
 *
 * Copyright (c) 2011 Yuya Nishihara <yuya@tcha.org>
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2 or any later version.
 */

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "hgclient.h"
#include "util.h"

#ifndef UNIX_PATH_MAX
#define UNIX_PATH_MAX (sizeof(((struct sockaddr_un *)NULL)->sun_path))
#endif

struct cmdserveropts {
	char sockname[UNIX_PATH_MAX];
	char lockfile[UNIX_PATH_MAX];
	char pidfile[UNIX_PATH_MAX];
	size_t argsize;
	const char **args;
};

static void initcmdserveropts(struct cmdserveropts *opts) {
	memset(opts, 0, sizeof(struct cmdserveropts));
}

static void freecmdserveropts(struct cmdserveropts *opts) {
	free(opts->args);
	opts->args = NULL;
	opts->argsize = 0;
}

/*
 * Test if an argument is a sensitive flag that should be passed to the server.
 * Return 0 if not, otherwise the number of arguments starting from the current
 * one that should be passed to the server.
 */
static size_t testsensitiveflag(const char *arg)
{
	static const struct {
		const char *name;
		size_t narg;
	} flags[] = {
		{"--config", 1},
		{"--cwd", 1},
		{"--repo", 1},
		{"--repository", 1},
		{"--traceback", 0},
		{"-R", 1},
	};
	size_t i;
	for (i = 0; i < sizeof(flags) / sizeof(flags[0]); ++i) {
		size_t len = strlen(flags[i].name);
		size_t narg = flags[i].narg;
		if (memcmp(arg, flags[i].name, len) == 0) {
			if (arg[len] == '\0') {  /* --flag (value) */
				return narg + 1;
			} else if (arg[len] == '=' && narg > 0) {  /* --flag=value */
				return 1;
			} else if (flags[i].name[1] != '-') {  /* short flag */
				return 1;
			}
		}
	}
	return 0;
}

/*
 * Parse argv[] and put sensitive flags to opts->args
 */
static void setcmdserverargs(struct cmdserveropts *opts,
			     int argc, const char *argv[])
{
	size_t i, step;
	opts->argsize = 0;
	for (i = 0, step = 1; i < (size_t)argc; i += step, step = 1) {
		if (!argv[i])
			continue;  /* pass clang-analyse */
		if (strcmp(argv[i], "--") == 0)
			break;
		size_t n = testsensitiveflag(argv[i]);
		if (n == 0 || i + n > (size_t)argc)
			continue;
		opts->args = reallocx(opts->args,
				      (n + opts->argsize) * sizeof(char *));
		memcpy(opts->args + opts->argsize, argv + i,
		       sizeof(char *) * n);
		opts->argsize += n;
		step = n;
	}
}

static void preparesockdir(const char *sockdir)
{
	int r;
	r = mkdir(sockdir, 0700);
	if (r < 0 && errno != EEXIST)
		abortmsg("cannot create sockdir %s (errno = %d)",
			 sockdir, errno);

	struct stat st;
	r = lstat(sockdir, &st);
	if (r < 0)
		abortmsg("cannot stat %s (errno = %d)", sockdir, errno);
	if (!S_ISDIR(st.st_mode))
		abortmsg("cannot create sockdir %s (file exists)", sockdir);
	if (st.st_uid != geteuid() || st.st_mode & 0077)
		abortmsg("insecure sockdir %s", sockdir);
}

static void setcmdserveropts(struct cmdserveropts *opts)
{
	int r;
	char sockdir[UNIX_PATH_MAX];
	const char *envsockname = getenv("CHGSOCKNAME");
	if (!envsockname) {
		/* by default, put socket file in secure directory
		 * (permission of socket file may be ignored on some Unices) */
		const char *tmpdir = getenv("TMPDIR");
		if (!tmpdir)
			tmpdir = "/tmp";
		r = snprintf(sockdir, sizeof(sockdir), "%s/chg%d",
			     tmpdir, geteuid());
		if (r < 0 || (size_t)r >= sizeof(sockdir))
			abortmsg("too long TMPDIR (r = %d)", r);
		preparesockdir(sockdir);
	}

	const char *basename = (envsockname) ? envsockname : sockdir;
	const char *sockfmt = (envsockname) ? "%s" : "%s/server";
	const char *lockfmt = (envsockname) ? "%s.lock" : "%s/lock";
	const char *pidfmt = (envsockname) ? "%s.pid" : "%s/pid";
	r = snprintf(opts->sockname, sizeof(opts->sockname), sockfmt, basename);
	if (r < 0 || (size_t)r >= sizeof(opts->sockname))
		abortmsg("too long TMPDIR or CHGSOCKNAME (r = %d)", r);
	r = snprintf(opts->lockfile, sizeof(opts->lockfile), lockfmt, basename);
	if (r < 0 || (size_t)r >= sizeof(opts->lockfile))
		abortmsg("too long TMPDIR or CHGSOCKNAME (r = %d)", r);
	r = snprintf(opts->pidfile, sizeof(opts->pidfile), pidfmt, basename);
	if (r < 0 || (size_t)r >= sizeof(opts->pidfile))
		abortmsg("too long TMPDIR or CHGSOCKNAME (r = %d)", r);
}

/*
 * Make lock file that indicates cmdserver process is about to start. Created
 * lock file will be deleted by server. (0: success, -1: lock exists)
 */
static int lockcmdserver(const struct cmdserveropts *opts)
{
	int r;
	char info[32];
	r = snprintf(info, sizeof(info), "%d", getpid());
	if (r < 0 || (size_t)r >= sizeof(info))
		abortmsg("failed to format lock info");
	r = symlink(info, opts->lockfile);
	if (r < 0 && errno != EEXIST)
		abortmsg("failed to make lock %s (errno = %d)",
			 opts->lockfile, errno);
	return r;
}

static void execcmdserver(const struct cmdserveropts *opts)
{
	const char *hgcmd = getenv("CHGHG");
	if (!hgcmd || hgcmd[0] == '\0')
		hgcmd = getenv("HG");
	if (!hgcmd || hgcmd[0] == '\0')
		hgcmd = "hg";

	const char *baseargv[] = {
		hgcmd,
		"serve",
		"--cwd", "/",
		"--cmdserver", "chgunix",
		"--address", opts->sockname,
		"--daemon-postexec", opts->lockfile,
		"--pid-file", opts->pidfile,
		"--config", "extensions.chgserver=",
		/* wrap root ui so that it can be disabled/enabled by config */
		"--config", "progress.assume-tty=1",
	};
	size_t baseargvsize = sizeof(baseargv) / sizeof(baseargv[0]);
	size_t argsize = baseargvsize + opts->argsize + 1;

	const char **argv = mallocx(sizeof(char *) * argsize);
	memcpy(argv, baseargv, sizeof(baseargv));
	memcpy(argv + baseargvsize, opts->args, sizeof(char *) * opts->argsize);
	argv[argsize - 1] = NULL;

	if (execvp(hgcmd, (char **)argv) < 0)
		abortmsg("failed to exec cmdserver (errno = %d)", errno);
	free(argv);
}

/*
 * Sleep until lock file is deleted, i.e. cmdserver process starts listening.
 * If pid is given, it also checks if the child process fails to start.
 */
static void waitcmdserver(const struct cmdserveropts *opts, pid_t pid)
{
	static const struct timespec sleepreq = {0, 10 * 1000000};
	int pst = 0;

	for (unsigned int i = 0; i < 10 * 100; i++) {
		int r;
		struct stat lst;

		r = lstat(opts->lockfile, &lst);
		if (r < 0 && errno == ENOENT)
			return;  /* lock file deleted by server */
		if (r < 0)
			goto cleanup;

		if (pid > 0) {
			/* collect zombie if child process fails to start */
			r = waitpid(pid, &pst, WNOHANG);
			if (r != 0)
				goto cleanup;
		}

		nanosleep(&sleepreq, NULL);
	}

	abortmsg("timed out waiting for cmdserver %s", opts->lockfile);
	return;

cleanup:
	if (pid > 0)
		/* lockfile should be made by this process */
		unlink(opts->lockfile);
	if (WIFEXITED(pst)) {
		abortmsg("cmdserver exited with status %d", WEXITSTATUS(pst));
	} else if (WIFSIGNALED(pst)) {
		abortmsg("cmdserver killed by signal %d", WTERMSIG(pst));
	} else {
		abortmsg("error white waiting cmdserver");
	}
}

/* Spawn new background cmdserver */
static void startcmdserver(const struct cmdserveropts *opts)
{
	debugmsg("start cmdserver at %s", opts->sockname);

	if (lockcmdserver(opts) < 0) {
		debugmsg("lock file exists, waiting...");
		waitcmdserver(opts, 0);
		return;
	}

	/* remove dead cmdserver socket if any */
	unlink(opts->sockname);

	pid_t pid = fork();
	if (pid < 0)
		abortmsg("failed to fork cmdserver process");
	if (pid == 0) {
		/* bypass uisetup() of pager extension */
		int nullfd = open("/dev/null", O_WRONLY);
		if (nullfd >= 0) {
			dup2(nullfd, fileno(stdout));
			close(nullfd);
		}
		execcmdserver(opts);
	} else {
		waitcmdserver(opts, pid);
	}
}

static void killcmdserver(const struct cmdserveropts *opts, int sig)
{
	FILE *fp = fopen(opts->pidfile, "r");
	if (!fp)
		abortmsg("cannot open %s (errno = %d)", opts->pidfile, errno);
	int pid = 0;
	int n = fscanf(fp, "%d", &pid);
	fclose(fp);
	if (n != 1 || pid <= 0)
		abortmsg("cannot read pid from %s", opts->pidfile);

	if (kill((pid_t)pid, sig) < 0) {
		if (errno == ESRCH)
			return;
		abortmsg("cannot kill %d (errno = %d)", pid, errno);
	}
}

static pid_t peerpid = 0;

static void forwardsignal(int sig)
{
	assert(peerpid > 0);
	if (kill(peerpid, sig) < 0)
		abortmsg("cannot kill %d (errno = %d)", peerpid, errno);
	debugmsg("forward signal %d", sig);
}

static void handlestopsignal(int sig)
{
	sigset_t unblockset, oldset;
	struct sigaction sa, oldsa;
	if (sigemptyset(&unblockset) < 0)
		goto error;
	if (sigaddset(&unblockset, sig) < 0)
		goto error;
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = SIG_DFL;
	sa.sa_flags = SA_RESTART;
	if (sigemptyset(&sa.sa_mask) < 0)
		goto error;

	forwardsignal(sig);
	if (raise(sig) < 0)  /* resend to self */
		goto error;
	if (sigaction(sig, &sa, &oldsa) < 0)
		goto error;
	if (sigprocmask(SIG_UNBLOCK, &unblockset, &oldset) < 0)
		goto error;
	/* resent signal will be handled before sigprocmask() returns */
	if (sigprocmask(SIG_SETMASK, &oldset, NULL) < 0)
		goto error;
	if (sigaction(sig, &oldsa, NULL) < 0)
		goto error;
	return;

error:
	abortmsg("failed to handle stop signal (errno = %d)", errno);
}

static void setupsignalhandler(pid_t pid)
{
	if (pid <= 0)
		return;
	peerpid = pid;

	struct sigaction sa;
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = forwardsignal;
	sa.sa_flags = SA_RESTART;
	if (sigemptyset(&sa.sa_mask) < 0)
		goto error;

	if (sigaction(SIGHUP, &sa, NULL) < 0)
		goto error;
	if (sigaction(SIGINT, &sa, NULL) < 0)
		goto error;

	/* terminate frontend by double SIGTERM in case of server freeze */
	sa.sa_flags |= SA_RESETHAND;
	if (sigaction(SIGTERM, &sa, NULL) < 0)
		goto error;

	/* propagate job control requests to worker */
	sa.sa_handler = forwardsignal;
	sa.sa_flags = SA_RESTART;
	if (sigaction(SIGCONT, &sa, NULL) < 0)
		goto error;
	sa.sa_handler = handlestopsignal;
	sa.sa_flags = SA_RESTART;
	if (sigaction(SIGTSTP, &sa, NULL) < 0)
		goto error;

	return;

error:
	abortmsg("failed to set up signal handlers (errno = %d)", errno);
}

/* This implementation is based on hgext/pager.py (pre 369741ef7253) */
static void setuppager(hgclient_t *hgc, const char *const args[],
		       size_t argsize)
{
	const char *pagercmd = hgc_getpager(hgc, args, argsize);
	if (!pagercmd)
		return;

	int pipefds[2];
	if (pipe(pipefds) < 0)
		return;
	pid_t pid = fork();
	if (pid < 0)
		goto error;
	if (pid == 0) {
		close(pipefds[0]);
		if (dup2(pipefds[1], fileno(stdout)) < 0)
			goto error;
		if (isatty(fileno(stderr))) {
			if (dup2(pipefds[1], fileno(stderr)) < 0)
				goto error;
		}
		close(pipefds[1]);
		hgc_attachio(hgc);  /* reattach to pager */
		return;
	} else {
		dup2(pipefds[0], fileno(stdin));
		close(pipefds[0]);
		close(pipefds[1]);

		int r = execlp("/bin/sh", "/bin/sh", "-c", pagercmd, NULL);
		if (r < 0) {
			abortmsg("cannot start pager '%s' (errno = %d)",
				 pagercmd, errno);
		}
		return;
	}

error:
	close(pipefds[0]);
	close(pipefds[1]);
	abortmsg("failed to prepare pager (errno = %d)", errno);
}

int main(int argc, const char *argv[], const char *envp[])
{
	if (getenv("CHGDEBUG"))
		enabledebugmsg();

	struct cmdserveropts opts;
	initcmdserveropts(&opts);
	setcmdserveropts(&opts);
	setcmdserverargs(&opts, argc, argv);

	if (argc == 2) {
		int sig = 0;
		if (strcmp(argv[1], "--kill-chg-daemon") == 0)
			sig = SIGTERM;
		if (strcmp(argv[1], "--reload-chg-daemon") == 0)
			sig = SIGHUP;
		if (sig > 0) {
			killcmdserver(&opts, sig);
			return 0;
		}
	}

	hgclient_t *hgc = hgc_open(opts.sockname);
	if (!hgc) {
		startcmdserver(&opts);
		hgc = hgc_open(opts.sockname);
	}
	if (!hgc)
		abortmsg("cannot open hg client");

	setupsignalhandler(hgc_peerpid(hgc));
	hgc_setenv(hgc, envp);
	setuppager(hgc, argv + 1, argc - 1);
	int exitcode = hgc_runcommand(hgc, argv + 1, argc - 1);
	hgc_close(hgc);
	freecmdserveropts(&opts);
	return exitcode;
}
