local ffi = require "ffi"
local resty_signal = require "resty.signal"
local C = ffi.C
local ffi_new = ffi.new
local signum_native = resty_signal.signum_native

local _M = {
    version = 0.1
}

ffi.cdef [[
    int fork(void);
    int wait(int *wstatus);
    int waitpid(int pid, int *wstatus, int options);
    int getppid(void);
    int getpid(void);
    typedef void (*sighandler_t)(int);
    sighandler_t signal(int signum, sighandler_t handler);
    typedef struct {
      unsigned long int __val[16];
    } __sigset_t;
    typedef __sigset_t sigset_t;
    int sigemptyset(sigset_t *set);
    int sigfillset(sigset_t *set);
    int sigaddset(sigset_t *set, int signum);
    int sigdelset(sigset_t *set, int signum);
    int sigismember(const sigset_t *set, int signum);
    int sigprocmask(int how, const sigset_t *set,
           sigset_t *oset);
]]

local wait_options = {
    WNOHANG = 1, --/* Don't block waiting.  */
    WUNTRACED = 2, --/* Report status of stopped children.  */
    WSTOPPED = 2, --/* Report stopped child (same as WUNTRACED). */
    WEXITED = 4, --/* Report dead child.  */
    WCONTINUED = 8, --/* Report continued child.  */
    WNOWAIT = 0x01000000, -- /* Don't reap, just poll status.  */
    WNOTHREAD = 0x20000000, -- /* Don't wait on children of other threads in this group */
    WALL = 0x40000000, -- /* Wait for any child.  */
    WCLONE = 0x80000000 --/* Wait for cloned process.  */
}

local sigprocmask_how = {
    SIG_BLOCK = 1,
    SIG_UNBLOCK = 2,
    SIG_SETMASK = 3
}

local function fork()
    local pid = ffi.C.fork()
    local err = nil
    if -1 == pid then
        err = "fork failed"
    end

    return pid, err
end

--[[
    return pid, ws
]]
local function waitpid(pid, options)
    local ws = ffi_new("int[1]", 0)
    local ret = C.waitpid(-1, ws, options)
    return ret, tonumber(ws)
end

--[[
    return pid
]]
local function waitpid()
    local ws = ffi_new("int[1]", 0)
    local ret = C.wait(ws)
    return ret
end

local function getpid()
    return tonumber(getpid())
end

local function getppid()
    return tonumber(getppid())
end

local function signal(sig, sighandler)
    local signum, err
    if type(signum) == "number" then
        signum = sig
    else
        signum, err = signum_native(sig)
    end

    if err then
        return nil, err
    end

    local cb = ffi_new(ffi.typeof("sighandler_t"), sighandler)

    return C.signal(signum, cb)
end

local function signewset()
    local sigset = ffi_new("sigset_t[1]")
    C.sigemptyset(sigset)
    return sigset
end

local function sigemptyset(sigset)
    C.sigemptyset(sigset)
    return sigset
end

local function sigfillset(sigset)
    C.sigfillset(sigset)
    return sigset
end

local function sigaddset(sigset, sig)
    local signum, err = signum_native(sig)
    if err then
        return nil, err
    end

    return C.sigaddset(sigset, signum)
end

local function sigdelset(sigset, sig)
    local signum, err = signum_native(sig)
    if err then
        return nil, err
    end

    return C.sigdelset(sigset, signum)
end

local function sigismember(sigset, sig)
    local signum, err = signum_native(sig)
    if err then
        return nil, err
    end

    return C.sigismember(sigset, signum)
end

--[[
    return ok, oldsigset
]]
local function sigprocmask(how, sigset)
    local oldsigset = signewset()
    return C.sigprocmask(how, sigset, oldsigset)
end

_M.fork = fork
_M.waitpid = waitpid
_M.signal = signal
return _M
