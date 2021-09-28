" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :
"
" vim_completes.vim - Tiny tab completion
" Maintainer:          Euris <http://github.com/euris>
" Version:             0.0.1
" Website:             <http://github.com/euris/vim_completes>
"
" Features:
"
" - auto popup complete window without select the first one
" - tab/s-tab to cycle suggestions, <c-e> to cancel
" - use VimCompletesEnable/VimCompletesDisable to toggle for certiain file.
"
" Usage:
"
" set cpt=.,k,b
" set completeopt=menu,menuone,noselect
" let g:vim_completes_enable_ft = {'text':1, 'markdown':1, 'php':1}

let g:vim_completes_enable_ft = get(g:, 'vim_completes_enable_ft', {})    " enable filetypes
let g:vim_completes_enable_tab = get(g:, 'vim_completes_enable_tab', 1)   " remap tab
let g:vim_completes_min_length = get(g:, 'vim_completes_min_length', 2)   " minimal length to open popup
let g:vim_completes_key_ignore = get(g:, 'vim_completes_key_ignore', [])  " ignore keywords

" get word before cursor
function! s:get_context()
	return strpart(getline('.'), 0, col('.') - 1)
endfunc

function! s:meets_keyword(context)
	if g:vim_completes_min_length <= 0
		return 0
	endif
	let matches = matchlist(a:context, '\(\k\{' . g:vim_completes_min_length . ',}\)$')
	if empty(matches)
		return 0
	endif
	for ignore in g:vim_completes_key_ignore
		if stridx(ignore, matches[1]) == 0
			return 0
		endif
	endfor
	return 1
endfunc

function! s:check_back_space() abort
	  return col('.') < 2 || getline('.')[col('.') - 2]  =~# '\s'
endfunc

function! s:on_backspace()
	if pumvisible() == 0
		return "\<BS>"
	endif
	let text = matchstr(s:get_context(), '.*\ze.')
	return s:meets_keyword(text)? "\<BS>" : "\<c-e>\<bs>"
endfunc


" autocmd for CursorMovedI
function! s:feed_popup()
	let enable = get(b:, 'vim_completes_enable', 0)
	let lastx = get(b:, 'vim_completes_lastx', -1)
	let lasty = get(b:, 'vim_completes_lasty', -1)
	let tick = get(b:, 'vim_completes_tick', -1)
	if &bt != '' || enable == 0 || &paste
		return -1
	endif
	let x = col('.') - 1
	let y = line('.') - 1
	if pumvisible()
		let context = s:get_context()
		if s:meets_keyword(context) == 0
			call feedkeys("\<c-e>", 'n')
		endif
		let b:vim_completes_lastx = x
		let b:vim_completes_lasty = y
		let b:vim_completes_tick = b:changedtick
		return 0
	elseif lastx == x && lasty == y
		return -2
	elseif b:changedtick == tick
		let lastx = x
		let lasty = y
		return -3
	endif
	let context = s:get_context()
	if s:meets_keyword(context)
		silent! call feedkeys("\<c-n>", 'n')
		let b:vim_completes_lastx = x
		let b:vim_completes_lasty = y
		let b:vim_completes_tick = b:changedtick
	endif
	return 0
endfunc

" autocmd for CompleteDone
function! s:complete_done()
	let b:vim_completes_lastx = col('.') - 1
	let b:vim_completes_lasty = line('.') - 1
	let b:vim_completes_tick = b:changedtick
endfunc

" enable vim_completes
function! s:vim_completes_enable()
	call s:vim_completes_disable()
	augroup VimCompletesEventGroup
		au!
		au CursorMovedI <buffer> nested call s:feed_popup()
		au CompleteDone <buffer> call s:complete_done()
	augroup END
	let b:vim_completes_init_autocmd = 1
	if g:vim_completes_enable_tab
		inoremap <silent><buffer><expr> <tab>
					\ pumvisible()? "\<c-n>" :
					\ <SID>check_back_space() ? "\<tab>" : "\<c-n>"
		inoremap <silent><buffer><expr> <s-tab>
					\ pumvisible()? "\<c-p>" : "\<s-tab>"
		let b:vim_completes_init_tab = 1
	endif
	if get(g:, 'vim_completes_cr_confirm', 0) == 0
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>\<cr>" : "\<cr>"
	else
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>" : "\<cr>"
	endif
	inoremap <silent><buffer><expr> <bs> <SID>on_backspace()
	let b:vim_completes_init_bs = 1
	let b:vim_completes_init_cr = 1
	let b:vim_completes_save_infer = &infercase
	setlocal infercase
	let b:vim_completes_enable = 1
endfunc

" disable vim_completes
function! s:vim_completes_disable()
	if get(b:, 'vim_completes_init_autocmd', 0)
		augroup VimCompletesEventGroup
			au! 
		augroup END
	endif
	if get(b:, 'vim_completes_init_tab', 0)
		silent! iunmap <buffer><expr> <tab>
		silent! iunmap <buffer><expr> <s-tab>
	endif
	if get(b:, 'vim_completes_init_bs', 0)
		silent! iunmap <buffer><expr> <bs>
	endif
	if get(b:, 'vim_completes_init_cr', 0)
		silent! iunmap <buffer><expr> <cr>
	endif
	if get(b:, 'vim_completes_save_infer', '') != ''
		let &l:infercase = b:vim_completes_save_infer
	endif
	let b:vim_completes_init_autocmd = 0
	let b:vim_completes_init_tab = 0
	let b:vim_completes_init_bs = 0
	let b:vim_completes_init_cr = 0
	let b:vim_completes_save_infer = ''
	let b:vim_completes_enable = 0
endfunc

" check if need to be enabled
function! s:vim_completes_check_init()
	if &bt != ''
		return
	endif
	if get(g:vim_completes_enable_ft, &ft, 0) != 0
		VimCompletesEnable
	elseif get(g:vim_completes_enable_ft, '*', 0) != 0
		VimCompletesEnable
	elseif get(b:, 'vim_completes_enable', 0)
		VimCompletesEnable
	endif
endfunc

" commands & autocmd
command! -nargs=0 VimCompletesEnable call s:vim_completes_enable()
command! -nargs=0 VimCompletesDisable call s:vim_completes_disable()

augroup VimCompletesInitGroup
	au!
	au FileType * call s:vim_completes_check_init()
	au BufEnter * call s:vim_completes_check_init()
	au TabEnter * call s:vim_completes_check_init()
augroup END
