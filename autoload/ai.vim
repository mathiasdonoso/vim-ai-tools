vim9script

export def AICallAsync(backend: string, model: string, prompt: string, config: dict<string>, Callback: func(list<string>)): number
    var cmd: list<string> = []
    if backend == 'claude'
        cmd = ['claude', '-p', '--output-format', 'text']

        const effort = get(config, 'effort', '')
        if effort != ''
            cmd->add('--effort')
            cmd->add(effort)
        endif

        const disallowed_tools = get(config, 'disallowed_tools', '')
        if disallowed_tools != ''
            cmd->add('--disallowedTools')
            cmd->add(disallowed_tools)
        endif

        const system_prompt = get(config, 'system_prompt', '')
        if system_prompt != ''
            cmd->add(get(config, 'system_prompt_flag', '--append-system-prompt'))
            cmd->add(system_prompt)
        endif

        if model != ''
            cmd->add('--model')
            cmd->add(model)
        endif
    endif

    if empty(cmd)
        throw '[ai] Unsupported backend: ' .. backend
    endif

    return core#CallAsync(cmd, prompt, Callback)
enddef
