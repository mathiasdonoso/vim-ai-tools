vim9script

def InitSetup(line1: number, line2: number): dict<any>
    const lines = getline(line1, line2)
    const text = join(lines, "\n")
    if trim(text) == ''
        throw 'AIExplain: Selection is empty'
    endif

    var system_prompt = get(g:, 'explain_prompt', '')
    if empty(system_prompt)
        throw 'AIExplain: system prompt is empty'
    endif

    const backend = get(g:, 'explain_backend', 'claude')
    if !executable(backend)
        throw 'AIExplain: backend executable "' .. backend .. '" not found in PATH'
    endif

    const model = get(g:, 'explain_model', '')

    var filename = expand('%:t')
    var prompt = 'Filename: ' .. filename .. "\nCode:\n" .. text

    return {
        prompt: prompt,
        backend: backend,
        model: model,
    }
enddef

export def ExplainCode(line1: number, line2: number): void
    try
        ui#SpinnerStart('Thinking...')

        const config = InitSetup(line1, line2)
        const lines = ai#AICall(config.backend, config.model, config.prompt)

        ui#DisplayResult(lines)
    catch
        echohl ErrorMsg
        echom '[ExplainCode] ' .. v:exception
        echohl None
    finally
        ui#SpinnerStop()
    endtry
enddef
