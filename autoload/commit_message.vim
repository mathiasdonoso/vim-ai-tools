vim9script

var current_jid: number = 0

# TODO: Fix commit message generator — buffer behavior differs when starting in `:Git` vs `:Git commit`
export def GenerateMessage(): void
    if core#IsRunning(current_jid)
        return
    endif

    const backend = get(g:, 'commit_message_backend', 'claude')
    if !executable(backend)
        throw '[AICommitMessage] backend executable "' .. backend .. '" not found in PATH'
    endif

    var git_dir = system('git rev-parse --git-dir')->trim()
    if v:shell_error != 0
        echohl ErrorMsg
        echom '[AICommitMessage] Not in a git repository'
        echohl None
        return
    endif

    try
        ui#SpinnerStart('Generating commit message')
        var stat = system('git diff --staged --no-color --stat')
        var diff = system('git diff --staged --unified=3 --no-color')
        var prompt = $"Summary of changes:\n{stat}\n\nFull diff:\n{diff}"

        const model = get(g:, 'commit_message_model', '')

        current_jid = AICallAsync(backend, model, prompt, (lines) => {
            try
                var commit_file = git_dir .. '/COMMIT_EDITMSG'

                var existing = filereadable(commit_file) ? readfile(commit_file) : []
                var new_content = lines + (len(existing) > 1 ? existing[1 : ] : [])
                writefile(new_content, commit_file)

                execute 'edit ' .. commit_file
                setlocal textwidth=72
                normal! gg
                execute 'normal! gq' .. len(lines) .. 'G'
                ui#SpinnerStop()
            catch
                ui#SpinnerStop()
                echohl ErrorMsg
                echom '[AICommitMessage] ' .. v:exception
                echohl None
            endtry
        })
    catch
        ui#SpinnerStop()
        echohl ErrorMsg
        echom '[AICommitMessage] ' .. v:exception
        echohl None
    endtry
enddef

export def GenerateMessageCancel(): void
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif
    ui#SpinnerStop()
    echo '[AICommitMessage]: cancelled pending request'
enddef

export def AICallAsync(backend: string, model: string, prompt: string, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = [
            'claude', '-p',
            '--output-format', 'text',
            '--effort', 'low',
            '--disallowedTools', 'Bash,Write,Edit,Read',
            '--append-system-prompt', get(g:, 'commit_message_prompt'),
        ]

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw '[AICommitMessage] Unsupported backend: ' .. backend
    endif

    return core#CallAsync(cmd, prompt, Callback)
enddef
