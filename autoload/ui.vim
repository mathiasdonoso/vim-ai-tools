vim9script

var spinner_timer: number = -1
var spinner_step: number = 0
var spinner_msg: string = ''

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
    spinner_timer = timer_start(400, function('SpinnerTick'), {repeat: -1})
enddef

export def SpinnerStop()
    if spinner_timer != -1
        timer_stop(spinner_timer)
        spinner_timer = -1
    endif
    echo ''
enddef

def SpinnerTick(timer_id: number)
    var dots = repeat('.', spinner_step % 3 + 1)
    echo spinner_msg .. dots
    spinner_step += 1
enddef
