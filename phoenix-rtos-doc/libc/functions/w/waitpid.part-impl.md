# Synopsis <!-- #MUST_BE: make good synopsis -->

`#include <sys/wait.h>` <!-- #MUST_BE: check status according to implementation -->

`pid_t waitpid(pid_t pid, int *status, int options)`

`pid_t wait(int *status)`

## Status

Partially implemented

## Conformance

IEEE Std 1003.1-2017 <!-- #MUST_BE: if function shall be posix compliant print the standard signature  -->

## Description

The `wait()` and `waitpid()` functions shall obtain status information pertaining to one of the caller's child
processes. The `wait()` function obtains status information for process termination from any child process. The
`waitpid()` function obtains status information for process termination, and optionally process stop and/or continue,
from a specified subset of the child processes.

The `wait()` function shall cause the calling thread to become blocked until status information generated by child
process termination is made available to the thread, or until delivery of a signal whose action is either to execute a
signal-catching function or to terminate the process, or an error occurs. If termination status information is available
prior to the call to wait(), return shall be immediate. If termination status information is available for two or more
child processes, the order in which their status is reported is unspecified.

The `wait()` and `waitpid()` functions consume the status information they obtain.

The behavior when multiple threads are blocked in `wait()`, `waitid()`, or `waitpid()` is described in Status
Information.<!-- #ISSUE:STATUS-INFORMATION-DOC-MISSING# -->

The `waitpid()` function shall be equivalent to `wait()` if the pid argument is `(pid_t)-1` and the options argument
is `0`. Otherwise, its behavior shall be modified by the values of the pid and options arguments.

The pid argument specifies a set of child processes for which status is requested. The `waitpid()` function shall only
return the status of a child process from this set:

* If pid is equal to `(pid_t)-1`, status is requested for any child process. In this respect, `waitpid()` is then
equivalent to `wait()`.

* If pid is greater than `0`, it specifies the process ID of a single child process for which status is requested.

* If pid is `0`, status is requested for any child process whose process group ID is equal to that of the calling
process.

* If pid is less than `(pid_t)-1`, status is requested for any child process whose process group ID is equal to the
absolute value of pid.

The options argument is constructed from the bitwise-inclusive OR of zero or more of the following flags, defined in
the `<sys/wait.h>` header:

* `WCONTINUED` - The `waitpid()` function shall report the status of any continued child process specified by pid whose
status has not been reported since it continued from a job control stop.

* `WNOHANG` - The `waitpid()` function shall not suspend execution of the calling thread if status is not immediately
available for one of the child processes specified by pid.

* `WUNTRACED` - The status of any child processes specified by pid that are stopped, and whose status has not yet been
reported since they stopped, shall also be reported to the requesting process.

If `wait()` or `waitpid()` return because the status of a child process is available, these functions shall return a
value equal to the process ID of the child process. In this case, if the value of the argument stat_loc is not a null
pointer, information shall be stored in the location pointed to by stat_loc. The value stored at the location pointed
to by stat_loc shall be `0` if and only if the status returned is from a terminated child process that terminated by
one of the following means:

* The process returned `0` from `main()`.

* The process called `_exit()` or `exit()` with a status argument of `0`.

* The process was terminated because the last thread in the process terminated.

Regardless of its value, this information may be interpreted using the following macros, which are defined in
`<sys/wait.h>` and evaluate to integral expressions; the stat_val argument is the integer value pointed to by stat_loc.

* `WIFEXITED(stat_val)` - Evaluates to a non-zero value if status was returned for a child process that terminated
normally.

* `WEXITSTATUS(stat_val)` - If the value of `WIFEXITED(stat_val)` is non-zero, this macro evaluates to the low-order 8
bits of the status argument that the child process passed to `_exit()` or `exit()`, or the value the child process
returned from `main()`.

* `WIFSIGNALED(stat_val)` - Evaluates to a non-zero value if status was returned for a child process that terminated
due to the receipt of a signal that was not caught (see `<signal.h>`).

* `WTERMSIG(stat_val)` - If the value of WIFSIGNALED(stat_val) is non-zero, this macro evaluates to the number of the
signal that caused the termination of the child process.

* `WIFSTOPPED(stat_val)` - Evaluates to a non-zero value if status was returned for a child process that is currently
stopped.

* `WSTOPSIG(stat_val)` - If the value of WIFSTOPPED(stat_val) is non-zero, this macro evaluates to the number of the
signal that caused the child process to stop.

* `WIFCONTINUED(stat_val)` - Evaluates to a non-zero value if status was returned for a child process that has continued
from a job control stop.

It is unspecified whether the status value returned by calls to `wait()` or `waitpid()` for processes created by
`posix_spawn()` or `posix_spawnp()` can indicate a `WIFSTOPPED(stat_val)` before subsequent calls to `wait()` or
`waitpid()` indicate `WIFEXITED(stat_val)` as the result of an error detected before the new process image starts
executing.

It is unspecified whether the status value returned by calls to `wait()` or `waitpid()` for processes created by
`posix_spawn()` or `posix_spawnp()` can indicate a `WIFSIGNALED(stat_val)` if a signal is sent to the parent's process
group after `posix_spawn()` or `posix_spawnp()` is called.

If the information pointed to by `stat_loc` was stored by a call to `waitpid()` that specified the `WUNTRACED` flag and
did not specify the `WCONTINUED` flag, exactly one of the macros `WIFEXITED(stat_loc)`, `WIFSIGNALED(stat_loc)`, and
`WIFSTOPPED(stat_loc)` shall evaluate to a non-zero value.

If the information pointed to by `stat_loc` was stored by a call to `waitpid()` that specified the `WUNTRACED` and
`WCONTINUED` flags, exactly one of the macros `WIFEXITED(stat_loc)`, `WIFSIGNALED(stat_loc)`, `WIFSTOPPED(stat_loc)`,
and `WIFCONTINUED(stat_loc)` shall evaluate to a non-zero value.

If the information pointed to by `stat_loc` was stored by a call to `waitpid()` that did not specify the `WUNTRACED` or
`WCONTINUED` flags, or by a call to the `wait()` function, exactly one of the macros `WIFEXITED(stat_loc)` and
`WIFSIGNALED(stat_loc)` shall evaluate to a non-zero value.

If the information pointed to by `stat_loc` was stored by a call to `waitpid()` that did not specify the `WUNTRACED`
flag and specified the `WCONTINUED` flag, exactly one of the macros `WIFEXITED(stat_loc)`, `WIFSIGNALED(stat_loc)`, and
`WIFCONTINUED(stat_loc)` shall evaluate to a non-zero value.

If `_POSIX_REALTIME_SIGNALS` is defined, and the implementation queues the `SIGCHLD` signal, then if `wait()` or
`waitpid()` returns because the status of a child process is available, any pending `SIGCHLD` signal associated with the
process ID of the child process shall be discarded. Any other pending `SIGCHLD` signals shall remain pending.

Otherwise, if `SIGCHLD` is blocked, if `wait()` or `waitpid()` return because the status of a child process is
available, any pending `SIGCHLD` signal shall be cleared unless the status of another child process is available.

For all other conditions, it is unspecified whether child status will be available when a `SIGCHLD`signal is delivered.

There may be additional implementation-defined circumstances under which `wait()` or `waitpid()` report status.

This shall not occur unless the calling process or one of its child processes explicitly makes use of a non-standard
extension. In these cases the interpretation of the reported status is implementation-defined.

If a parent process terminates without waiting for all of its child processes to terminate, the remaining child
processes shall be assigned a new parent process ID corresponding to an implementation-defined system process.

## Return value

`wait()` or `waitpid()` shall return a value equal to the process ID of the child process for which status is reported.
If `wait()` or `waitpid()` returns due to the delivery of a signal to the calling process, `EINTR`. If `waitpid()` was
invoked with `WNOHANG` set in options, it has at least one child process specified by pid for which status is not
available, and status is not available for any process specified by pid, `0` is returned. Otherwise, `-1` shall be
returned, and errno set to indicate the error.

## Errors

The `wait()` function shall fail if:

* `ECHILD` - the calling process has no existing _unwaited-for_ child processes.

* `EINTR` - the function was interrupted by a signal. The value of the location pointed to by stat_loc is undefined.

The `waitpid()` function shall fail if:

* `ECHILD` - the process specified by pid does not exist or is not a child of the calling process, or the process group
specified by pid does not exist or does not have any member process that is a child of the calling process.

* `EINTR` - the function was interrupted by a signal. The value of the location pointed to by stat_loc is undefined.

* `EINVAL` - the options argument is not valid.

## Tests

Untested
<!-- #MUST_BE: function by default shall be untested, when tested there should be a link to test location and 
test command for ia32 test runner  -->

## Known bugs

* Description
  * `WIFSTOPPED(stat_val)`, `WSTOPSIG(stat_val)`, `WIFCONTINUED(stat_val)` always return `0`
  * `WNOHANG` option does not work ([Issue link](https://github.com/phoenix-rtos/phoenix-rtos-project/issues/184))
  * `waitpid()` does not discard a pending `SIGCHLD`signal that is associated with a successfully waited-for child
  process. ([Issue link](https://github.com/phoenix-rtos/phoenix-rtos-project/issues/188))

## See Also

1. [Standard library functions](../README.md)
2. [Table of Contents](../../../README.md)