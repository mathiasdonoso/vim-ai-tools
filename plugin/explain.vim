vim9script

if !exists('g:explain_prompt')
    g:explain_prompt = join([
        'You are a code explanation engine.',
        '',
        'Explain the provided code clearly and concisely.',
        '',
        'Rules:',
        '- Do not modify the code.',
        '- Do not include unnecessary verbosity.',
        '- Focus on what the code does and why.',
        '- Assume the reader is a developer.',
    ], "\n")
endif

if !exists('g:explain_backend')
    g:explain_backend = 'claude'
endif

if !exists('g:explain_model')
    g:explain_model = 'claude-haiku-4-5-20251001'
endif

command! -range=% AIExplain call explain#ExplainCode(<line1>, <line2>)
