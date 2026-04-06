vim9script

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
    # TODO
enddef

export def SpinnerStop()
    # TODO
enddef
