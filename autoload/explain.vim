vim9script

def InitSetup(line1: number, line2: number): dict<string>
    var lines = getline(line1, line2)
    var text = join(lines, "\n")
    if trim(text) == ''
        throw 'AIExplain: Selection is empty'
    endif

    var prompt = get(g:, 'explain_prompt', '')
    if empty(prompt)
        throw 'AIExplain: Prompt is empty'
    endif

    prompt ..= "\nCode: " .. text
    prompt ..= "\nIf you receive no text, output exactly: ERROR:NO_TEXT"

    var backend = get(g:, 'explain_backend', 'claude')
    if backend != 'claude'
        throw 'AIExplain: unknown backend "' .. backend .. '"'
    endif

    if !executable(backend)
        throw 'AIExplain: backend executable "' .. backend .. '" not found in PATH'
    endif

    var model = get(g:, 'explain_model', '')

    return {
        prompt: prompt,
        backend: backend,
        model: model,
    }
enddef

export def ExplainCode(line1: number, line2: number)
    try
        var config = InitSetup(line1, line2)
        var cmd: list<string> = ['claude', '-p', config.prompt, '--output-format', 'text']
        if config.model != ''
            cmd->add('--model')
            cmd->add(config.model)
        endif

        var cmd_str = join(map(copy(cmd), 'shellescape(v:val)'), ' ')
        var result = system(cmd_str)
        var lines = split(result, "\n")

        DisplayResult(lines)
    catch
        echohl ErrorMsg
        echom v:exception
        echohl None
        return
    endtry
enddef

def DisplayResult(lines: list<string>)
    aboveleft new

    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted

    setlocal modifiable
    call setline(1, lines)
    setlocal nomodifiable

    setlocal wrap
    setlocal linebreak
    resize 15
enddef
