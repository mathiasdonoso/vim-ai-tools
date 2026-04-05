vim9script

export def ExplainCode(line1: number, line2: number)
    var lines = getline(line1, line2)
    var text = join(lines, "\n")

    if trim(text) == ""
        echoerr "AIExplain: Selection is empty"
        return
    endif

    var prompt = get(g:, "explain_prompt", "")
    if empty(prompt)
        echoerr "AIExplain: Prompt is empty"
        return
    endif

    prompt ..= "
                \. If you receive no text, output exactly: ERROR:NO_TEXT"

    var backend = get(g:, "explain_backend", "claude")
    if backend != "claude"
        echoerr "AIExplain: unknown backend \"" .. backend .. "\""
        return
    endif

    if !executable(backend)
        echoerr "AIExplain: backend executable \"" .. backend .. "\" not found in PATH"
        return
    endif

    var model = get(g:, "explain_model", "")
    var cmd: list<string> = ["claude", "-p", prompt, "--output-format", "text"]
    if model != ""
        cmd->add("--model")
        cmd->add(model)
    endif

    echo "Result -> model: " .. model .. ", backend: " .. backend .. ", prompt: " .. prompt
enddef
