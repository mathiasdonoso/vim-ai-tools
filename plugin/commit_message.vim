vim9script

if !exists('g:commit_message_prompt')
    g:commit_message_prompt = join([
        'You are a Git commit message generator. Given a git diff, write a concise and meaningful commit message following these rules:',
        '',
        '- First line: short summary under 72 characters, use conventional commits format (type: description) where type is one of: feat, fix, docs, style, refactor, test, chore',
        '- If needed, add a blank line followed by a brief body explaining *what* and *why*, not *how*',
        '- Be specific, avoid vague messages like "fix bug" or "update code"',
        '- Do not include any explanation, commentary, or formatting — output only the commit message',
        '- Output only the commit message text, no markdown, no code blocks, no backticks, no formatting of any kind.',
    ], "\n")
endif

if !exists('g:commit_message_backend')
    g:commit_message_backend = 'claude'
endif

if !exists('g:commit_message_model')
    g:commit_message_model = 'haiku'
endif

command! AICommitMessage call commit_message#GenerateMessage()
