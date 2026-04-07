vim9script

var registry: dict<dict<any>> = {}
var job_id_counter: number = 0

export def CallAsync(cmd: list<string>, stdin_data: string, Callback: func(list<string>)): number
    job_id_counter += 1
    var jid = job_id_counter
    var jid_str = string(jid)
 
    registry[jid_str] = {
        job:         null_job,
        stdout:      [],
        stderr:      [],
        Callback:    Callback,
        closed:      false,
        exited:      false,
        exit_status: 0,
    }
 
    var job = job_start(cmd, {
        in_io:    'pipe',
        out_io:   'pipe',
        err_io:   'pipe',
        out_mode: 'nl',
        err_mode: 'nl',
        out_cb:   (ch, msg) => OnStdout(jid_str, ch, msg),
        err_cb:   (ch, msg) => OnStderr(jid_str, ch, msg),
        close_cb: (ch)      => OnClose(jid_str, ch),
        exit_cb:  (j, st)   => OnExit(jid_str, j, st),
    })
 
    if job_status(job) == 'fail'
        remove(registry, jid_str)
        throw '[async_job] Failed to start: ' .. join(cmd, ' ')
    endif
 
    registry[jid_str].job = job
 
    # Pipe stdin and close input
    var ch = job_getchannel(job)
    ch_sendraw(ch, stdin_data)
    ch_close_in(ch)
 
    return jid
enddef

export def Cancel(jid: number): void
    var jid_str = string(jid)
    if !has_key(registry, jid_str)
        return
    endif
    var job = registry[jid_str].job
    if job_status(job) == 'run'
        job_stop(job)
    endif
    remove(registry, jid_str)
enddef

# Guard against multiple calls
export def IsRunning(jid: number): bool
    var jid_str = string(jid)
    if !has_key(registry, jid_str)
        return false
    endif
    return job_status(registry[jid_str].job) == 'run'
enddef

def OnStdout(jid_str: string, ch: channel, msg: string)
    if has_key(registry, jid_str)
        add(registry[jid_str].stdout, msg)
    endif
enddef
 
def OnStderr(jid_str: string, ch: channel, msg: string)
    if has_key(registry, jid_str)
        add(registry[jid_str].stderr, msg)
    endif
enddef
 
def OnClose(jid_str: string, ch: channel)
    if !has_key(registry, jid_str)
        return
    endif
    registry[jid_str].closed = true
    MaybeFinish(jid_str)
enddef

def OnExit(jid_str: string, j: job, status: number)
    if !has_key(registry, jid_str)
        return
    endif
    registry[jid_str].exit_status = status
    registry[jid_str].exited = true
    MaybeFinish(jid_str)
enddef

def MaybeFinish(jid_str: string)
    if !has_key(registry, jid_str)
        return
    endif

    var entry = registry[jid_str]
    if !entry.closed || !entry.exited
        return
    endif

    remove(registry, jid_str)

    if !empty(entry.stderr)
        echohl WarningMsg
        echo '[async_job] stderr: ' .. join(entry.stderr, "\n")
        echohl None
    endif

    if entry.exit_status != 0
        echohl ErrorMsg
        echom '[async_job] command exited with status ' .. entry.exit_status
        echohl None
        return
    endif

    try
        entry.Callback(entry.stdout)
    catch
        echohl ErrorMsg
        echom '[async_job] callback error: ' .. v:exception
        echohl None
    endtry
enddef
