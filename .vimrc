colorscheme sorbet

set nu
set ts=4
set shiftwidth=4
set expandtab
set softtabstop=4
set mouse=a
set scrolloff=0

set hlsearch
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

command! -nargs=* -complete=shellcmd R cgetexpr system(<q-args>) | copen

function! Find(pattern)
    let l:cwd = getcwd()
    let l:buffers = getbufinfo({'buflisted': 1})
    let l:external_files = []

    for l:buf in l:buffers
        if len(l:buf.name) == 0
            continue
        endif

        let l:full_path = fnamemodify(l:buf.name, ':p')

        if stridx(l:full_path, l:cwd) != 0
            " it is external buffers
            call add(l:external_files, shellescape(l:full_path))
        endif
    endfor

    let l:cmd = 'rg --vimgrep ' . a:pattern . ' . ' . join(l:external_files, ' ')
    cgetexpr system(l:cmd)
    copen
endfunction

command! -nargs=* -complete=file F call Find(<q-args>)

vnoremap <C-f>   "sy:F <C-r>=shellescape(@s)<CR>
nnoremap <C-f> "syiw:F <C-r>=shellescape(@s)<CR>

