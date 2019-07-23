" This is copied from https://github.com/natebosch/vim-lsc/blob/master/autoload/lsc/diff.vim
"
" Computes a simplistic diff between [old] and [new].
"
" Returns a dict with keys `range`, `rangeLength`, and `text` matching the LSP
" definition of `TextDocumentContentChangeEvent`.
"
" Finds a single change between the common prefix, and common postfix.
function! lsp#utils#diff#compute(old, new) abort
  let [l:start_line, l:start_char] = s:FirstDifference(a:old, a:new)
  let [l:end_line, l:end_char] =
      \ s:LastDifference(a:old[l:start_line :], a:new[l:start_line :], l:start_char)

  let l:text = s:ExtractText(a:new, l:start_line, l:start_char, l:end_line, l:end_char)
  let l:length = s:Length(a:old, l:start_line, l:start_char, l:end_line, l:end_char)

  let l:adj_end_line = len(a:old) + l:end_line
  let l:adj_end_char = l:end_line == 0 ? 0 : strchars(a:old[l:end_line]) + l:end_char + 1

  let l:result = { 'range': {'start': {'line': l:start_line, 'character': l:start_char},
      \  'end': {'line': l:adj_end_line, 'character': l:adj_end_char}},
      \ 'text': l:text,
      \ 'rangeLength': l:length,
      \}

  return l:result
endfunction

" Finds the line and character of the first different character between two
" list of Strings.
function! s:FirstDifference(old, new) abort
  let l:line_count = min([len(a:old), len(a:new)])
  if l:line_count ==# 0
    return [0, 0]
  endif
  let l:i = 0
  while l:i < l:line_count
    if a:old[l:i] !=# a:new[l:i] | break | endif
    let l:i += 1
  endwhile
  if l:i >= l:line_count
    return [l:line_count - 1, strchars(a:old[l:line_count - 1])]
  endif
  let l:old_line = split(a:old[l:i], '\zs')
  let l:new_line = split(a:new[l:i], '\zs')
  let l:length = min([len(l:old_line), len(l:new_line)])
  let l:j = 0
  while l:j < l:length
    if l:old_line[l:j : l:j] !=# l:new_line[l:j : l:j] | break | endif
    let l:j += 1
  endwhile
  return [l:i, l:j]
endfunction

function! s:LastDifference(old, new, start_char) abort
  let l:line_count = min([len(a:old), len(a:new)])
  if l:line_count == 0 | return [0, 0] | endif
  let l:i = -1
  while l:i >= -1 * l:line_count
    if a:old[l:i] !=# a:new[l:i] | break | endif
    let l:i -= 1
  endwhile
  if l:i <= -1 * l:line_count
    let l:i = -1 * l:line_count
    let l:old_line = split(a:old[l:i], '\zs')[a:start_char :]
    let l:new_line = split(a:new[l:i], '\zs')[a:start_char :]
  else
    let l:old_line = split(a:old[l:i], '\zs')
    let l:new_line = split(a:new[l:i], '\zs')
  endif
  let l:length = min([len(l:old_line), len(l:new_line)])
  let l:j = -1
  while l:j >= -1 * l:length
    if l:old_line[l:j : l:j] !=# l:new_line[l:j : l:j] | break | endif
    let l:j -= 1
  endwhile
  return [l:i, l:j]
endfunction

function! s:ExtractText(lines, start_line, start_char, end_line, end_char) abort
  if a:start_line == len(a:lines) + a:end_line
    if a:end_line == 0 | return '' | endif
    let l:length = strchars(a:lines[a:start_line]) - a:start_char + a:end_char + 1
    let l:result = strcharpart(a:lines[a:start_line], a:start_char, l:length)
    " json_encode treats empty string computed this was as 'null'
    if strlen(l:result) == 0 | let l:result = '' | endif
    return l:result
  endif
  let l:length = strchars(a:lines[a:start_line]) - a:start_char
  let l:result = strcharpart(a:lines[a:start_line], a:start_char, l:length)."\n"
  for l:line in a:lines[a:start_line + 1 : a:end_line - 1]
    let l:result .= l:line."\n"
  endfor
  if a:end_line != 0
    let l:length = strchars(a:lines[a:end_line]) + a:end_char + 1
    let l:result .= strcharpart(a:lines[a:end_line], 0, l:length)
  endif
  return l:result
endfunction

function! s:Length(lines, start_line, start_char, end_line, end_char)
    \ abort
  let l:adj_end_line = len(a:lines) + a:end_line
  if l:adj_end_line >= len(a:lines)
    let l:adj_end_char = a:end_char - 1
  else
    let l:adj_end_char = strchars(a:lines[l:adj_end_line]) + a:end_char
  endif
  if a:start_line == l:adj_end_line
    return l:adj_end_char - a:start_char + 1
  endif
  let l:result = strchars(a:lines[a:start_line]) - a:start_char + 1
  let l:line = a:start_line + 1
  while l:line < l:adj_end_line
    let l:result += strchars(a:lines[l:line]) + 1
    let l:line += 1
  endwhile
  let l:result += l:adj_end_char + 1
  return l:result
endfunction
