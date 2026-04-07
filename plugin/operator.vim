vim9script

if !exists('g:operator_prompt')
    g:operator_prompt = join([
        'You are a deterministic code transformation engine.',
        '',
        '- Use the filename to identify the programming language.',
        '- Modify ONLY what is explicitly requested. Preserve everything else exactly — logic, formatting, comments, structure.',
        '- Do NOT refactor, optimize, or improve anything unless explicitly asked.',
        '- Output raw code only. No markdown, no backticks, no explanations, no comments.',
        '- If no code is provided, generate from scratch based on the instruction.',
        '- If the instruction is unclear or inapplicable, return the original code unchanged.',
    ], "\n")
endif

if !exists('g:operator_backend')
    g:operator_backend = 'claude'
endif

if !exists('g:operator_model')
    g:operator_model = 'sonnet'
endif

command! -range=% -nargs=1 AIOperator call operator#Code(<line1>, <line2>, <q-args>)
command! AIOperatorCancel call operator#CodeCancel()

