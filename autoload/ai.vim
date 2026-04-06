vim9script

export def AICall(backend: string, model: string, prompt: string): list<string>
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = ['claude', '-p', '-', '--output-format', 'text']

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw 'Unsupported backend: ' .. backend
    endif

    const cmd_str = join(map(copy(cmd), 'shellescape(v:val)'), ' ')
    const result = system(cmd_str, prompt)

    if v:shell_error != 0
        throw 'Command failed (' .. v:shell_error .. '): ' .. result
    endif

    return split(trim(result), "\n")
enddef
