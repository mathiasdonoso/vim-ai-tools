vim9script

var spinner_timer: number = -1
var spinner_step: number = 0
var spinner_msg: string = ''

var selection_timer: number = -1
var selection_step: number = 0
var selection_bufnr: number = -1
var selection_match_ids: list<number> = []
var selection_winid: number = -1
const SELECTION_SPINNER_FRAMES = ['|', '/', '-', '\']
const SELECTION_SIGN_GROUP = 'AIProcessing'
const SELECTION_SIGN_NAME = 'AIProcessingSign'

highlight default AIProcessing ctermbg=237 guibg=#3a3a3a ctermfg=250 guifg=#bcbcbc

export def DisplayResult(lines: list<string>)
    aboveleft new

    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted

    setlocal modifiable
    call setline(1, lines)
    setlocal nomodifiable

    setlocal wrap
    setlocal linebreak
    resize 15
enddef

export def SpinnerStart(message: string)
    spinner_msg = message
    spinner_step = 0
    SpinnerTick(0)
    spinner_timer = timer_start(150, function('SpinnerTick'), {repeat: -1})
enddef

export def SpinnerStop()
    if spinner_timer != -1
        timer_stop(spinner_timer)
        spinner_timer = -1
    endif
    echo ''
enddef

def SpinnerTick(timer_id: number)
    var frame = SELECTION_SPINNER_FRAMES[spinner_step % len(SELECTION_SPINNER_FRAMES)]
    echo spinner_msg .. ' ' .. frame
    spinner_step += 1
enddef

export def SelectionStart(bufnr: number, line1: number, line2: number)
    selection_bufnr = bufnr
    selection_step = 0
    selection_winid = win_getid()

    selection_match_ids = []
    var lines = range(line1, line2)
    var i = 0
    while i < len(lines)
        var chunk = lines[i : i + 7]
        var positions = mapnew(chunk, (_, l) => [l])
        var mid = matchaddpos('AIProcessing', positions, 10, -1, {window: selection_winid})
        add(selection_match_ids, mid)
        i += 8
    endwhile

    sign_define(SELECTION_SIGN_NAME, {text: SELECTION_SPINNER_FRAMES[0], texthl: 'Comment'})
    for lnum in lines
        sign_place(lnum, SELECTION_SIGN_GROUP, SELECTION_SIGN_NAME, bufnr, {lnum: lnum})
    endfor

    SelectionTick(0)
    selection_timer = timer_start(150, function('SelectionTick'), {repeat: -1})
enddef

export def SelectionStop()
    if selection_timer != -1
        timer_stop(selection_timer)
        selection_timer = -1
    endif

    for mid in selection_match_ids
        try
            matchdelete(mid, selection_winid)
        catch
        endtry
    endfor
    selection_match_ids = []

    if selection_bufnr != -1
        sign_unplace(SELECTION_SIGN_GROUP, {buffer: selection_bufnr})
    endif

    selection_bufnr = -1
    selection_winid = -1
enddef

def SelectionTick(timer_id: number)
    if selection_bufnr == -1
        return
    endif

    var frame = SELECTION_SPINNER_FRAMES[selection_step % len(SELECTION_SPINNER_FRAMES)]
    sign_define(SELECTION_SIGN_NAME, {text: frame, texthl: 'Comment'})
    selection_step += 1
enddef
