vim9script

if !exists('g:grammar_prompt')
    g:grammar_prompt = join([
        'You are an English writing assistant.',
        '',
        'Rules:',
        '- Improve the grammar, clarity, and style of the provided text.',
        '- Preserve the original meaning and structure.',
        '- Output ONLY the improved text.',
        '- No preamble, explanations, or comments.',
        '- If you receive no text, output exactly: ERROR:NO_TEXT',
    ], "\n")
endif

if !exists('g:grammar_backend')
    g:grammar_backend = 'claude'
endif

if !exists('g:grammar_model')
    g:grammar_model = 'haiku'
endif

command! -range=% AIGrammar call grammar#ImproveGrammar(<line1>, <line2>)
command! AIGrammarCancel call grammar#ImproveGrammarCancel()
