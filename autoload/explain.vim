vim9script

var current_jid: number = 0

def BuildPrompt(line1: number, line2: number): string
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    if trim(text) == ''
        throw 'AIExplain: Selection is empty'
    endif

    const filename = expand('%:t')
    return 'Filename: ' .. filename .. "\nCode:\n" .. text
enddef

export def ExplainCode(line1: number, line2: number): void
    if core#IsRunning(current_jid)
        return
    endif

    try
        ui#SpinnerStart('Thinking')

        var system_prompt = get(g:, 'explain_prompt', '')
        if empty(system_prompt)
            throw 'AIExplain: system prompt is empty'
        endif

        const backend = get(g:, 'explain_backend', 'claude')
        if !executable(backend)
            throw 'AIExplain: backend executable "' .. backend .. '" not found in PATH'
        endif

        const model = get(g:, 'explain_model', '')
        const prompt = BuildPrompt(line1, line2)

        current_jid = AICallAsync(backend, model, prompt, (lines) => {
            ui#SpinnerStop()
            ui#DisplayResult(lines)
        })
    catch
        ui#SpinnerStop()
        echohl ErrorMsg
        echom '[ExplainCode] ' .. v:exception
        echohl None
    endtry
enddef

export def ExplainCodeCancel(): void
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif

    echo 'AI: cancelled pending request'
enddef

# TODO: analize the --bare option for claude and add configuration to enable or disable it.
# Requires ANTHROPIC_API_KEY
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

    return core#CallAsync(cmd, prompt, Callback)
enddef
