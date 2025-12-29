#include <errno.h>
#include <mach-o/dyld.h>
#include <sys/event.h>
#include <sys/stat.h>
#include <sys/syslimits.h>
#include <time.h>
#include <unistd.h>

#define TIMEOUT 10

char *get_shell() {
  switch (getuid()) {
#include "mappings"
  default:
    return "/bin/zsh";
  }
}

#define CHECK(cond)                                                            \
  if ((cond) != 0) {                                                           \
    return __LINE__;                                                           \
  }

int main(int argc, char **argv) {
  char buf[PATH_MAX];
  uint32_t size = sizeof(buf);
  CHECK(_NSGetExecutablePath(buf, &size));

  struct stat st;
  CHECK(stat(buf, &st));
  if (st.st_uid != 0 || (st.st_mode & 0777) != 0755) {
    return __LINE__;
  }

  char *shell = get_shell();

  struct timespec start, now;
  if (access(shell, R_OK) != 0) {
    int saved_errno = errno;
    int kq = kqueue();
    clock_gettime(CLOCK_MONOTONIC, &start);
    struct kevent kev = {
        .ident = 0,
        .filter = EVFILT_FS,
        .flags = EV_ADD,
        .fflags = 0,
        .data = 0,
        .udata = NULL,
    };
    if (kevent(kq, &kev, 1, NULL, 0, NULL) != 0) {
      return __LINE__;
    }
    do {
      switch (saved_errno) {
      case ENOENT:
      case ENOTDIR:
        clock_gettime(CLOCK_MONOTONIC, &now);
        if (now.tv_sec - start.tv_sec > TIMEOUT) {
          return __LINE__;
        }
        kevent(kq, NULL, 0, &kev, 1, NULL);
        break;
      default:
        return saved_errno;
      }
    } while (access(shell, R_OK) != 0 && (saved_errno = errno));
    close(kq);
  }

  argv[0] = shell;
  if (execv(shell, argv) == -1) {
    return errno;
  }
  return 0; // This line will never be reached if execv succeeds
}
