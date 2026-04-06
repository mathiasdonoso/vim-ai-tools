vim9script

# TODO: analize the --bare option for claude and add configuration to enable or disable it.
# Requires ANTHROPIC_API_KEY

var registry: dict<dict<any>> = {}
var job_id_counter: number = 0

export def AICallAsync(backend: string, model: string, prompt: string, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = [
            'claude', '-p',
            '--output-format', 'text',
            '--effort', 'medium',
            '--disallowedTools', 'Bash', 'Write', 'Edit', 'Read',
            '--append-system-prompt', get(g:, 'explain_prompt'),
        ]

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw 'Unsupported backend: ' .. backend
    endif

    return CallAsync(cmd, prompt, Callback)
enddef

export def CallAsync(cmd: list<string>, stdin_data: string, Callback: func(list<string>)): number
    job_id_counter += 1
    var jid = job_id_counter
    var jid_str = string(jid)
 
    registry[jid_str] = {
        job:      null_job,
        stdout:   [],
        stderr:   [],
        Callback: Callback,
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
        echoerr '[async_job] Failed to start: ' .. join(cmd, ' ')
        return -1
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
 
    var entry = registry[jid_str]
 
    if !empty(entry.stderr)
        echohl WarningMsg
        echo '[async_job] stderr: ' .. join(entry.stderr, "\n")
        echohl None
    endif
 
    entry.Callback(entry.stdout)
    remove(registry, jid_str)
enddef
 
def OnExit(jid_str: string, j: job, status: number)
    if has_key(registry, jid_str)
        registry[jid_str].exit_status = status
    endif
enddef
