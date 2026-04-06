vim9script

def InitSetup(line1: number, line2: number): dict<string>
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    if trim(text) == ''
        throw 'AIExplain: Selection is empty'
    endif

    var prompt = get(g:, 'explain_prompt', '')
    if empty(prompt)
        throw 'AIExplain: Prompt is empty'
    endif

    prompt ..= "\nCode: " .. text
    prompt ..= "\nIf you receive no text, output exactly: ERROR:NO_TEXT"

    const backend = get(g:, 'explain_backend', 'claude')
    if backend != 'claude'
        throw 'AIExplain: unknown backend "' .. backend .. '"'
    endif

    if !executable(backend)
        throw 'AIExplain: backend executable "' .. backend .. '" not found in PATH'
    endif

    const model = get(g:, 'explain_model', '')

    return {
        prompt: prompt,
        backend: backend,
        model: model,
    }
enddef

export def ExplainCode(line1: number, line2: number)
    try
        const config = InitSetup(line1, line2)
        var cmd: list<string> = ['claude', '-p', config.prompt, '--output-format', 'text']
        if config.model != ''
            cmd->add('--model')
            cmd->add(config.model)
        endif

        const cmd_str = join(map(copy(cmd), 'shellescape(v:val)'), ' ')
        const result = system(cmd_str)
        const lines = split(result, "\n")

        ui#DisplayResult(lines)
    catch
        echohl ErrorMsg
        echom v:exception
        echohl None
        return
    endtry
enddef
