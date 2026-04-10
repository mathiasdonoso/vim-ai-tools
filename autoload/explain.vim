vim9script

var current_jid: number = 0

# TODO: Do something when no text is received
def BuildPrompt(line1: number, line2: number): string
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    if trim(text) == ''
        throw '[AIExplain] Selection is empty'
    endif

    const filename = expand('%:t')
    return 'Filename: ' .. filename .. "\nCode:\n" .. text
enddef

export def ExplainCode(line1: number, line2: number): void
    if core#IsRunning(current_jid)
        return
    endif

    try
        ui#SelectionStart(bufnr('%'), line1, line2)

        var system_prompt = get(g:, 'explain_prompt', '')
        if empty(system_prompt)
            throw '[AIExplain] system prompt is empty'
        endif

        const backend = get(g:, 'explain_backend', 'claude')
        if !executable(backend)
            throw '[AIExplain] backend executable "' .. backend .. '" not found in PATH'
        endif

        const model = get(g:, 'explain_model', '')
        const prompt = BuildPrompt(line1, line2)

        current_jid = ai#AICallAsync(backend, model, prompt,
            ai#Config(get(g:, 'explain_prompt'), '--append-system-prompt', 'Bash,Write,Edit,Read', 'medium'),
            (lines) => {
            try
                ui#SelectionStop()
                ui#DisplayResult(lines)
            catch
                ui#SelectionStop()
                echohl ErrorMsg
                echom '[AIExplain] ' .. v:exception
                echohl None
            endtry
        })
    catch
        ui#SelectionStop()
        echohl ErrorMsg
        echom '[AIExplain] ' .. v:exception
        echohl None
    endtry
enddef

export def ExplainCodeCancel(): void
    if core#IsRunning(current_jid)
        core#Cancel(current_jid)
    endif
    ui#SelectionStop()
    echo '[AIExplain]: cancelled pending request'
enddef

