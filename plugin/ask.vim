vim9script

if !exists('g:ask_prompt')
    g:ask_prompt = join([
        'You are a precise and knowledgeable assistant.',
        '',
        'Rules:',
        '- Answer the question using the provided context if available.',
        '- If context is provided, prioritize it over general knowledge.',
        '- If context is insufficient, use general knowledge but say only what is necessary.',
        '- Be concise but complete.',
        '- Do NOT include meta commentary.',
        '- If the question is unclear, output exactly: ERROR:UNCLEAR_QUESTION',
        '- If you receive no text, output exactly: ERROR:NO_TEXT',
        '- Output ONLY the answer.',
    ], "\n")
endif

if !exists('g:ask_backend')
    g:ask_backend = 'claude'
endif

if !exists('g:ask_model')
    g:ask_model = 'sonnet'
endif

command! AIAsk call ask#Ask(<q-args>)
command! AIAskCancel call ask#AskCancel()
