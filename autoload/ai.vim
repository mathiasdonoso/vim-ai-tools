vim9script

# Build a config dict for AICallAsync.
#   system_prompt       - system prompt string (required)
#   system_prompt_flag  - '--system-prompt' or '--append-system-prompt' (default)
#   disallowed_tools    - comma-separated tool names (default: 'Bash,Write,Edit,Read')
#   effort              - 'low', 'medium', 'high', or '' to omit (default: '')
export def Config(
    system_prompt: string,
    system_prompt_flag: string = '--append-system-prompt',
    disallowed_tools: string = 'Bash,Write,Edit,Read',
    effort: string = ''
): dict<string>
    return {
        system_prompt: system_prompt,
        system_prompt_flag: system_prompt_flag,
        disallowed_tools: disallowed_tools,
        effort: effort,
    }
enddef

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
