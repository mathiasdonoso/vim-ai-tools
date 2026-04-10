vim9script

var current_jid: number = 0

def BuildPrompt(line1: number, line2: number): string
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    if trim(text) == ''
        throw '[AIGrammar] Selection is empty'
    endif

    return "Text to improve:\n" .. text
enddef

export def ImproveGrammar(line1: number, line2: number): void
    if core#IsRunning(current_jid)
        return
    endif

    try
        ui#SelectionStart(bufnr('%'), line1, line2)

        var system_prompt = get(g:, 'grammar_prompt', '')
        if empty(system_prompt)
            throw '[AIGrammar] system prompt is empty'
        endif

        const backend = get(g:, 'grammar_backend', 'claude')
        if !executable(backend)
            throw '[AIGrammar] backend executable "' .. backend .. '" not found in PATH'
        endif

        const model = get(g:, 'grammar_model', '')
        const prompt = BuildPrompt(line1, line2)

        const buf = bufnr('%')
        current_jid = ai#AICallAsync(backend, model, prompt,
            ai#Config(get(g:, 'grammar_prompt'), '--system-prompt', 'Bash,Write,Edit,Read', 'low'),
            (lines) => {
            try
                const range = ui#SelectionGetRange()
                if empty(range)
                    ui#SelectionStop()
                    return
                endif
                deletebufline(buf, range[0], range[1])
                appendbufline(buf, range[0] - 1, lines)
                ui#SelectionStop()
            catch
                ui#SelectionStop()
                echohl ErrorMsg
                echom '[AIGrammar] ' .. v:exception
                echohl None
            endtry
        })
    catch
        ui#SelectionStop()
        echohl ErrorMsg
        echom '[AIGrammar] ' .. v:exception
        echohl None
    endtry
enddef

export def ImproveGrammarCancel(line1: number, line2: number)
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif
    ui#SelectionStop()
    echo '[AIGrammar]: cancelled pending request'
enddef

