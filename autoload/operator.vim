vim9script

var current_jid: number = 0

def BuildPrompt(line1: number, line2: number, instruction: string): string
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    const filename = expand('%:t')

    var prompt = $"Filename: {filename}\nInstruction: {instruction}"

    if trim(text) != ''
        prompt ..= $"\nCode:\n{text}"
    endif

    return prompt
enddef

export def Code(line1: number, line2: number, args: string): void
    if core#IsRunning(current_jid)
        return
    endif

    try
        ui#SelectionStart(bufnr('%'), line1, line2)

        var system_prompt = get(g:, 'explain_prompt', '')
        if empty(system_prompt)
            throw '[AIOperator] system prompt is empty'
        endif

        const backend = get(g:, 'explain_backend', 'claude')
        if !executable(backend)
            throw '[AIOperator] backend executable "' .. backend .. '" not found in PATH'
        endif

        const model = get(g:, 'explain_model', '')
        const prompt = BuildPrompt(line1, line2, args)

        current_jid = AICallAsync(backend, model, prompt, (lines) => {
            ui#SelectionStop()
            ui#DisplayResult(lines)
        })
    catch
        ui#SelectionStop()
        echohl ErrorMsg
        echom '[AIOperator] ' .. v:exception
        echohl None
    endtry
enddef

export def CodeCancel(): void
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif
    ui#SelectionStop()
    echo '[AIOperator]: cancelled pending request'
enddef

export def AICallAsync(backend: string, model: string, prompt: string, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = [
            'claude', '-p',
            '--output-format', 'text',
            '--effort', 'high',
            '--disallowedTools', 'Bash', 'Write', 'Edit', 'Read',
            '--append-system-prompt', get(g:, 'operator_prompt'),
        ]

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw '[AIOperator] Unsupported backend: ' .. backend
    endif

    return core#CallAsync(cmd, prompt, Callback)
enddef
