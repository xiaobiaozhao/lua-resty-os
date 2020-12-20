local ffi = require "ffi"
local _M = {}

ffi.cdef [[
    int fork(void);
    int wait(int *wstatus);
    int waitpid(int pid, int *wstatus, int options);
    int getpid(void);
    int getppid(void);
    typedef void (*sighandler_t)(int);
    sighandler_t signal(int signum, sighandler_t handler);
    void(*signal(int, void (*)(int)))(int);
    // Different systems have different definitions, and this version is not implemented
    // int sigaction(int sig, const struct sigaction *restrict act,
    //       struct sigaction *restrict oact);
]]

--[[
    new_proc: 
]]
local function fork(new_proc, ...)
    -- 1.check param

    -- 2.fork
    local pid = ffi.C.fork()
    if 0 == pid then
        if new_proc then
            return new_proc(...)
        end
    elseif pid < 0 then
    else
        --
    end

    return pid
end

local function signal(signum, handler)
    1. -- check param
    2. -- signal
    ffi.C.signal(signum, handler)
end

_M.fork = fork
_M.signal = signal
return _M
