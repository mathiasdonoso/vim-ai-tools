vim9script

# TODO: Fix commit message generator — buffer behavior differs when starting in `:Git` vs `:Git commit`

export def GenerateMessage(): void
    ui#SpinnerStart('Generating commit message')

    var stat = system('git diff --staged --no-color --stat')
    var diff = system('git diff --staged --unified=3 --no-color')
    var prompt = $"Summary of changes:\n{stat}\n\nFull diff:\n{diff}"

    const backend = get(g:, 'explain_backend', 'claude')
    if !executable(backend)
        throw '[AIExplain] backend executable "' .. backend .. '" not found in PATH'
    endif

    const model = get(g:, 'explain_model', '')

    AICallAsync(backend, model, prompt, (lines) => {
        var git_dir = system('git rev-parse --git-dir')->trim()
        var commit_file = git_dir .. '/COMMIT_EDITMSG'

        var existing = readfile(commit_file)
        var new_content = lines + existing[1 : ]
        writefile(new_content, commit_file)

        execute 'edit ' .. commit_file
        setlocal textwidth=72
        ui#SpinnerStop()
    })
enddef

export def AICallAsync(backend: string, model: string, prompt: string, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = [
            'claude', '-p',
            '--output-format', 'text',
            '--effort', 'low',
            '--append-system-prompt', get(g:, 'commit_message_prompt'),
        ]

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw '[AIExplain] Unsupported backend: ' .. backend
    endif

    return core#CallAsync(cmd, prompt, Callback)
enddef
