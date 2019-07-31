#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/syscall.h>
#include <unistd.h>

int main() {
    if (unshare(CLONE_NEWCGROUP|CLONE_NEWIPC|CLONE_NEWNET|CLONE_NEWNS|CLONE_NEWUTS) < 0) {
        perror("unshare");
        return 1;
    }

    if (mount(NULL, "/", NULL, MS_PRIVATE|MS_REC, NULL) < 0) {
        perror("mount private");
        return 1;
    }

    if (mount("/rootfs", "/rootfs", "bind", MS_BIND|MS_REC, NULL) < 0) {
        perror("mount bind");
        return 1;
    }

    if (syscall(SYS_pivot_root, "/rootfs", "/rootfs/old-root") < 0) {
        perror("pivot_root");
        return 1;
    }

    if (chdir("/") < 0) {
        perror("chdir");
        return 1;
    }

    if (umount2("/old-root", MNT_DETACH) < 0) {
        perror("umount2");
        return 1;
    }

    if (sethostname("play-perl6", strlen("play-perl6")) < 0) {
        perror("sethostname");
        return 1;
    }

    if (setgid(65534) < 0) {
        perror("setgid");
        return 1;
    }

    if (setuid(65534) < 0) {
        perror("setuid");
        return 1;
    }

    execl("/usr/bin/perl6", "/usr/bin/perl6", (char*) NULL);
    perror("execv");
    return 1;
}
