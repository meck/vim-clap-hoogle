" Author: meck <johan@meck.se>
" Description: Search hoogle

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:hoogle_bin = 'hoogle'
let s:preview_title = 'Info:'
let s:preview_max_height = 25

let s:old_query = ''

function! s:hoogle_sink(selected) abort
  let line = systemlist(s:hoogle_bin . ' -n=1 --link ' . '"' . s:format_search(a:selected) . '"')[0]
  if len(line) >= 2
    let split_line = split(line, ' -- ')
    if len(split_line) >= 2
      let link = split_line[1]
      call netrw#BrowseX(link, 0)
      call s:clear_job_and_matches()
    endif
  endif
endfunction

function! s:run_search(query) abort
  if !executable(s:hoogle_bin)
    call g:clap.abort('Cannot execute ' . s:hoogle_bin . ' is it installed?')
    return
  endif
  return s:hoogle_bin . ' -q --count=999 ' . '"' . a:query . '"'
endfunction

function! s:hoogle_on_typed() abort
  let query = g:clap.input.get()

  " Let the previous search be continued
  if s:old_query ==# query
    return
  endif

  if empty(query)
    call s:clear_job_and_matches()
    call g:clap.display.clear_highlight()
    call g:clap.display.clear()
    call g:clap.preview.close()
    return
  endif

  let s:old_query = query

  call s:clear_job_and_matches()
  call g:clap.display.clear()
  call g:clap.preview.close()

  call clap#rooter#try_set_cwd()
  call clap#rooter#run(function('clap#dispatcher#job_start'), s:run_search(query))
endfunction

" TODO open preview window for inital search
" TODO invesigate highlighting
function! s:hoogle_on_move() abort
  let cur_sel = s:format_search(g:clap.display.getcurline())

  if cur_sel ==# ''
    call g:clap.preview.close()
    return
  endif

  let lines = systemlist(s:hoogle_bin . ' --info ' . '"' . cur_sel . '"')
  let lines = filter(lines, 'v:val !=# ""')
  let lines = [s:preview_title] + lines
  call g:clap.preview.show(lines)

  noautocmd call win_gotoid(g:clap.preview.winid)
  setlocal nonumber norelativenumber

  highlight C_h_title gui=bold
  execute 'match C_h_title /^' . s:preview_title . '$/'

  let new_size = len(lines) < s:preview_max_height ? len(lines) : s:preview_max_height
  execute 'resize ' . new_size

  noautocmd call win_gotoid(g:clap.input.winid)
endfunction

" `Data.IntMap.Strict lookup :: Key -> IntMap a -> Maybe a` returns `Data.IntMap.Strict.lookup`
" `module Data.Text` returns `Data.Text`
" `package text` returns `+text`
" `Data.Text data/newtype/type Text` returns Data.Text.Text
" TODO classes
function! s:format_search(line)
  let l:split_line = split(a:line)
  if stridx(a:line, ' :: ') > 0
    return l:split_line[0] . '.' . l:split_line[1]
  elseif stridx(a:line, 'module ') == 0
    return l:split_line[1]
  elseif stridx(a:line, 'package ') == 0
    return '+' . l:split_line[1]
  elseif len(l:split_line) >= 3 && (
        \ l:split_line[1] ==# 'data' ||
        \ l:split_line[1] ==# 'newtype' ||
        \ l:split_line[1] ==# 'type'
        \ )
    return l:split_line[0] . '.' . l:split_line[2]
  endif
  return ''
endfunction

function! s:clear_job_and_matches() abort
  call clap#dispatcher#jobstop()
  call g:clap.display.clear_highlight()
endfunction

function! s:hoogle_exit() abort
  call clap#dispatcher#jobstop()
  let s:old_query = ''
endfunction

let s:hoogle = {}
let s:hoogle.sink = function('s:hoogle_sink')
let s:hoogle.on_typed = function('s:hoogle_on_typed')
let s:hoogle.on_move = function('s:hoogle_on_move')
let s:hoogle.on_exit = function('s:hoogle_exit')
let g:clap#provider#hoogle# = s:hoogle

let &cpoptions = s:save_cpo
unlet s:save_cpo
