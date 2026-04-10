vim9script

var current_jid: number = 0

def BuildPrompt(question: string): string
    const project_files = system('git ls-files --directory $(git rev-parse --show-toplevel)')->trim()

    if v:shell_error != 0
        echohl ErrorMsg
        echom '[AIAsk] Not in a git repository'
        echohl None
        return ''
    endif

    return $"Project files:\n{project_files}\nQuestion: {question}"
enddef

export def Ask(args: string): void
    if core#IsRunning(current_jid)
        return
    endif

    try
        ui#SpinnerStart('Thinking')

        var system_prompt = get(g:, 'ask_prompt', '')
        if empty(system_prompt)
            throw '[AIAsk] system prompt is empty'
        endif

        const backend = get(g:, 'ask_backend', 'claude')
        if !executable(backend)
            throw '[AIAsk] backend executable "' .. backend .. '" not found in PATH'
        endif

        const model = get(g:, 'ask_model', '')
        const prompt = BuildPrompt(args)
        const buf = bufnr('%')

        current_jid = AICallAsync(backend, model, prompt, (lines) => {
            try
                ui#SpinnerStop()
                ui#DisplayResult(lines)
            catch
                ui#SpinnerStop()
                echohl ErrorMsg
                echom '[AIAsk] ' .. v:exception
                echohl None
            endtry
        })
    catch
        ui#SpinnerStop()
        echohl ErrorMsg
        echom '[AIAsk] ' .. v:exception
        echohl None
    endtry
enddef

export def AskCancel(): void
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif
    ui#SpinnerStop()
    echo '[AIAsk]: cancelled pending request'
enddef

def AICallAsync(backend: string, model: string, prompt: string, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = [
            'claude', '-p',
            '--output-format', 'text',
            '--disallowedTools', 'Bash,Write,Edit',
            '--append-system-prompt', get(g:, 'ask_prompt'),
        ]

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw '[AIAsk] Unsupported backend: ' .. backend
    endif

    return core#CallAsync(cmd, prompt, Callback)
enddef
