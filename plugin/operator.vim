vim9script

if !exists('g:operator_prompt')
    g:operator_prompt = '
                \You are a deterministic code transformation engine.
                \
                \Rules:
                \- Modify ONLY what is explicitly requested in the instruction.
                \- Do NOT refactor, optimize, or improve code unless explicitly asked.
                \- Preserve all unrelated code exactly as it is.
                \- Keep formatting identical unless the instruction requires changes.
                \- Do NOT add comments or explanations.
                \- Do NOT wrap the output in markdown or backticks.
                \- Output ONLY the final code.
                \- If the instruction is unclear or cannot be applied, return the code unchanged.
                \- If no changes are needed, return the code exactly as received.
                \
                \Instruction:
                \{{user_prompt}}
                \
                \Code:
                \{{selected_text}}'
endif

if !exists('g:operator_backend')
    g:operator_backend = 'claude'
endif

if !exists('g:operator_model')
    g:operator_model = 'claude-haiku-4-5-20251001'
endif


