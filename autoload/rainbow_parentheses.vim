"==============================================================================
"  Description: Rainbow colors for parentheses, based on rainbow_parenthsis.vim
"               by Martin Krischik and others.
"==============================================================================

function! s:uniq(list)
  let ret = []
  let map = {}
  for items in a:list
    let ok = 1
    for item in filter(copy(items), '!empty(v:val)')
      if has_key(map, item)
        let ok = 0
      endif
      let map[item] = 1
    endfor
    if ok
      call add(ret, items)
    endif
  endfor
  return ret
endfunction

function! s:show_colors()
  for level in reverse(range(1, s:max_level))
    execute 'hi rainbowParensShell'.level
  endfor
endfunction

let s:generation = 0
function! rainbow_parentheses#activate(...)
  let force = get(a:000, 0, 0)
  if exists('#rainbow_parentheses') && get(b:, 'rainbow_enabled', -1) == s:generation && !force
    return
  endif

  let s:generation += 1
  let s:max_level = get(g:, 'rainbow#max_level', 8)

  " assume that colors are there
  call s:regions(s:max_level)

  command! -bang -nargs=? -bar RainbowParenthesesColors call s:show_colors()
  augroup rainbow_parentheses
    autocmd!
    autocmd ColorScheme,Syntax * call rainbow_parentheses#activate(1)
  augroup END
  let b:rainbow_enabled = s:generation
endfunction

function! rainbow_parentheses#deactivate()
  if exists('#rainbow_parentheses')
    for level in range(1, s:max_level)
      " FIXME How to cope with changes in rainbow#max_level?
      silent! execute 'hi clear rainbowParensShell'.level
      " FIXME buffer-local
      silent! execute 'syntax clear rainbowParens'.level
    endfor
    augroup rainbow_parentheses
      autocmd!
    augroup END
    augroup! rainbow_parentheses
    delc RainbowParenthesesColors
  endif
endfunction

function! rainbow_parentheses#toggle()
  if exists('#rainbow_parentheses')
    call rainbow_parentheses#deactivate()
  else
    call rainbow_parentheses#activate()
  endif
endfunction

function! s:regions(max)
  let pairs = get(g:, 'rainbow#pairs', [['(',')'], ['[', ']'], ['{', '}']])
  for level in range(1, a:max)
    let cmd = 'syntax region rainbowParens%d matchgroup=rainbowParensShell%d start=/%s/ end=/%s/ contains=%s'
    let children = extend(['TOP'], map(range(level, a:max), '"rainbowParens".v:val'))
    for pair in pairs
      let [open, close] = map(copy(pair), 'escape(v:val, "[]/")')
      execute printf(cmd, level, level, open, close, join(children, ','))
    endfor
  endfor
endfunction

