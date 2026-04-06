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
    if ai#IsRunning(current_jid)
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

        current_jid = ai#AICallAsync(backend, model, prompt, (lines) => {
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
    if ai#IsRunning(current_jid)
        ai#Cancel(current_jid)
    endif

    echo 'AI: cancelled pending request'
enddef
