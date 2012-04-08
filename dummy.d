//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

extern(C)int sigfillset(ulong *p){ return 0; }

extern(C)int sigdelset(ulong *p, int n){ return 0; }

extern(C) void _pthread_cleanup_pop( void*  c, int  execute ){ }

extern(C) void _pthread_cleanup_push(void*      c,
                       void*  routine,
                       void*                     arg){ }

extern(C) int backtrace(void **buffer, int size){ return 0; }

extern(C) char **backtrace_symbols(void **buffer, int size){ return null; }

extern(C) void backtrace_symbols_fd(void **buffer, int size, int fd){ }

extern (C) real strtold(const char *nptr, char **endptr){ return 0.0; }
