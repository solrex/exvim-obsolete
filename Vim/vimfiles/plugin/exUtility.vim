"=============================================================================
" File:        exUtility.vim
" Author:      Johnny
" Last Change: Wed 29 Oct 2006 01:05:03 PM EDT
" Version:     1.0
"=============================================================================
" You may use this code in whatever way you see fit.

if exists('loaded_exscript') || &cp
    finish
endif
let loaded_exscript=1

" -------------------------------------------------------------------------
"  variable part
" -------------------------------------------------------------------------
" Initialization <<<
" -------------------------------
" gloable varialbe initialization
" -------------------------------
" store the plugins buffer name, so we can ensure not recore name as edit-buffer
if !exists('g:exUT_plugin_list')
    let g:exUT_plugin_list = []
endif

" -------------------------------
" local variable initialization
" -------------------------------

" 
highlight def ex_SynHL1 gui=none guibg=LightCyan term=none cterm=none ctermbg=LightCyan
highlight def ex_SynHL2 gui=none guibg=LightMagenta term=none cterm=none ctermbg=LightMagenta
highlight def ex_SynHL3 gui=none guibg=LightRed term=none cterm=none ctermbg=LightRed

highlight def ex_SynSelectLine gui=none guibg=#bfffff term=none cterm=none ctermbg=LightCyan
highlight def ex_SynConfirmLine gui=none guibg=#ffe4b3 term=none cterm=none ctermbg=DarkYellow
highlight def ex_SynObjectLine gui=none guibg=#ffe4b3 term=none cterm=none ctermbg=DarkYellow

" store the highlight strings
let s:ex_HighLightText = ["","","",""]

" local script vairable initialization
let s:ex_editbuf_num = ""
let s:ex_pluginbuf_num = ""

" file browse
let s:ex_level_list = []
" >>>

" ------------------------
"  window functions
" ------------------------

" --ex_CreateWindow--
" Create window
" buffer_name : a string of the buffer_name
" window_direction : 'topleft', 'botright'
" use_vertical : 0, 1
" edit_mode : 'none', 'append', 'replace'
" init_func_name: 'none', 'function_name'
function! g:ex_CreateWindow( buffer_name, window_direction, window_size, use_vertical, edit_mode, init_func_name ) " <<<
    " If the window is open, jump to it
    let winnum = bufwinnr(a:buffer_name)
    if winnum != -1
        "Jump to the existing window
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif

        if a:edit_mode == 'append'
            exe 'normal! G'
        elseif a:edit_mode == 'replace'
            exe 'normal! ggdG'
        endif

        return
    endif

    " Create a new window. If user prefers a horizontal window, then open
    " a horizontally split window. Otherwise open a vertically split
    " window
    if a:use_vertical
        " Open a vertically split window
        let win_dir = 'vertical '
    else
        " Open a horizontally split window
        let win_dir = ''
    endif
    
    " If the tag listing temporary buffer already exists, then reuse it.
    " Otherwise create a new buffer
    let bufnum = bufnr(a:buffer_name)
    if bufnum == -1
        " Create a new buffer
        let wcmd = a:buffer_name
    else
        " Edit the existing buffer
        let wcmd = '+buffer' . bufnum
    endif

    " Create the ex_window
    exe 'silent! ' . win_dir . a:window_direction . ' 10' . ' split ' . wcmd
    exe win_dir . 'resize ' . a:window_size

    " Initialize the window
    if bufnum == -1
        call g:ex_InitWindow( a:init_func_name )
    endif

    " adjust with edit_mode
    if a:edit_mode == 'append'
        exe 'normal! G'
    elseif a:edit_mode == 'replace'
        exe 'normal! ggdG'
    endif

    " after create the window, record the bufname into the plugin list
    if index( g:exUT_plugin_list, fnamemodify(a:buffer_name,":p:t") ) == -1
        silent call add(g:exUT_plugin_list, fnamemodify(a:buffer_name,":p:t"))
    endif

endfunction " >>>

" --ex_InitWindow--
" Init window
" init_func_name: 'none', 'function_name'
function! g:ex_InitWindow(init_func_name) " <<<
    silent! setlocal filetype=ex_filetype

    " Folding related settings
    silent! setlocal foldenable
    silent! setlocal foldminlines=0
    silent! setlocal foldmethod=manual
    silent! setlocal foldlevel=9999

    " Mark buffer as scratch
    silent! setlocal buftype=nofile
    silent! setlocal bufhidden=hide
    silent! setlocal noswapfile
    silent! setlocal nobuflisted

    silent! setlocal nowrap

    " If the 'number' option is set in the source window, it will affect the
    " exTagSelect window. So forcefully disable 'number' option for the exTagSelect
    " window
    silent! setlocal nonumber
    set winfixheight
    set winfixwidth

    " Define hightlighting
    syntax match ex_SynError '^Error:.*'
    highlight def ex_SynError gui=none guifg=White guibg=Red term=none cterm=none ctermfg=White ctermbg=Red

    " Define the ex autocommands
    augroup ex_auto_cmds
        autocmd WinLeave * call g:ex_RecordCurrentBufNum()
    augroup end

    " avoid cwd change problem
    if exists( 'g:exES_PWD' )
        au BufEnter * silent exec 'lcd ' . g:exES_PWD
    endif

    if a:init_func_name != 'none'
        exe 'call ' . a:init_func_name . '()'
    endif
endfunction " >>>

" --ex_OpenWindow--
"  Open window
" buffer_name : a string of the buffer_name
" window_direction : 'topleft', 'botright'
" use_vertical : 0, 1
" edit_mode : 'none', 'append', 'replace'
" backto_editbuf : 0, 1
" init_func_name: 'none', 'function_name'
" call_func_name: 'none', 'function_name'
function! g:ex_OpenWindow( buffer_name, window_direction, window_size, use_vertical, edit_mode, backto_editbuf, init_func_name, call_func_name ) " <<<
    " if current editor buf is a plugin file type
    if &filetype == "ex_filetype"
        silent exec "normal \<Esc>"
    endif

    " go to edit buffer first, then open the window, this will avoid some bugs
    call g:ex_GotoEditBuffer()

    " If the window is open, jump to it
    let winnum = bufwinnr(a:buffer_name)
    if winnum != -1
        " Jump to the existing window
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif

        if a:edit_mode == 'append'
            exe 'normal! G'
        elseif a:edit_mode == 'replace'
            exe 'normal! ggdG'
        endif

        return
    endif

    " Open window
    call g:ex_CreateWindow( a:buffer_name, a:window_direction, a:window_size, a:use_vertical, a:edit_mode, a:init_func_name )

    if a:call_func_name != 'none'
        exe 'call ' . a:call_func_name . '()'
    endif

    if a:backto_editbuf
        " Need to jump back to the original window only if we are not
        " already in that window
        call g:ex_GotoEditBuffer()
    endif
endfunction " >>>

" --ex_CloseWindow--
"  Close window
function! g:ex_CloseWindow( buffer_name ) " <<<
    "Make sure the window exists
    let winnum = bufwinnr(a:buffer_name)
    if winnum == -1
        call g:ex_WarningMsg('Error: ' . a:buffer_name . ' window is not open')
        return
    endif

    " close window
    exe winnum . 'wincmd w'
    close

    " go back to edit buffer
    call g:ex_GotoEditBuffer()
    call g:ex_ClearObjectHighlight()
    
    "if winnr() == winnum
    "    let last_buf_num = bufnr('#') 
    "    " Already in the window. Close it and return
    "    if winbufnr(2) != -1
    "        " If a window other than the a:buffer_name window is open,
    "        " then only close the a:buffer_name window.
    "        close
    "    endif

    "    " Need to jump back to the original window only if we are not
    "    " already in that window
    "    let winnum = bufwinnr(last_buf_num)
    "    if winnr() != winnum
    "        exe winnum . 'wincmd w'
    "    endif
    "else
    "    " Goto the a:buffer_name window, close it and then come back to the 
    "    " original window
    "    let cur_buf_num = bufnr('%')
    "    exe winnum . 'wincmd w'
    "    close
    "    " Need to jump back to the original window only if we are not
    "    " already in that window
    "    let winnum = bufwinnr(cur_buf_num)
    "    if winnr() != winnum
    "        exe winnum . 'wincmd w'
    "    endif
    "endif
endfunction " >>>

" --ex_ToggleWindow--
" Toggle window
function! g:ex_ToggleWindow( buffer_name, window_direction, window_size, use_vertical, edit_mode, backto_editbuf, init_func_name, call_func_name ) " <<<
    " If exTagSelect window is open then close it.
    let winnum = bufwinnr(a:buffer_name)
    if winnum != -1
        call g:ex_CloseWindow(a:buffer_name)
        return
    endif

    call g:ex_OpenWindow( a:buffer_name, a:window_direction, a:window_size, a:use_vertical, a:edit_mode, a:backto_editbuf, a:init_func_name, a:call_func_name )
endfunction " >>>

" --ex_ResizeWindow
"  Resize window use increase value
function! g:ex_ResizeWindow( use_vertical, original_size, increase_size ) " <<<
    if a:use_vertical
        let new_size = a:original_size
        if winwidth('.') <= a:original_size
            let new_size = a:original_size + a:increase_size
        endif
        silent exe 'vertical resize ' . new_size
    else
        let new_size = a:original_size
        if winheight('.') <= a:original_size
            let new_size = a:original_size + a:increase_size
        endif
        silent exe 'resize ' . new_size
    endif
endfunction " >>>

" ------------------------
"  string functions
" ------------------------

" --ex_PutLine--
function! g:ex_PutLine( len, line_type ) " <<<
    let plen = a:len - strlen(getline('.'))
    if (plen > 0)
        execute 'normal! ' plen . 'A' . a:line_type
    endif
endfunction " >>>

" --ex_PutDefine--
function! g:ex_PutDefine() " <<<
    execute 'normal! ' . 'o' .   "/**\<CR>"
    execute 'normal! ' . "\<Home>c$" . " * =======================================\<CR>"
    execute 'normal! ' . "\<Home>c$" . " * \<CR>"
    execute 'normal! ' . "\<Home>c$" . " * =======================================\<CR>"
    execute 'normal! ' . "\<Home>c$" . " */"
endfunction " >>>

" --ex_PutHeader--
function! g:ex_PutHeader() " <<<
    execute 'normal! ' . "gg"
    execute 'normal! ' . "O" .   "// ======================================================================================\<CR>"
    execute 'normal! ' . "\<Home>c$" . "// File         : " . fnamemodify(expand('%'), ":t") . "\<CR>"
    execute 'normal! ' . "\<Home>c$" . "// Author       : Wu Jie \<CR>"
    execute 'normal! ' . "\<Home>c$" . "// Description  : \<CR>"
    execute 'normal! ' . "\<Home>c$" . "// ======================================================================================"
    execute 'normal! ' . "o"
endfunction " >>>

" --ex_PutMain--
function! g:ex_PutMain() " <<<
    execute 'normal! ' . 'o' .   "int main( int argv, char* argc[] )\<CR>"
    execute 'normal! ' . "\<Home>c$" . " {\<CR>"
    execute 'normal! ' . "\<Home>c$" . " }"
endfunction " >>>

" --ex_AlignDigit--
function! g:ex_AlignDigit( align_nr, digit ) " <<<
    let print_fmt = '%'.a:align_nr.'d'
    let str_digit = printf(print_fmt,a:digit)
    retur substitute(str_digit,' ', '0','g')
endfunction " >>>

" --ex_InsertIFZero--
function! g:ex_InsertIFZero() range " <<<
    let lstline = a:lastline + 1 
    call append( a:lastline , "#endif")
    call append( a:firstline -1 , "#if 0")
    exec ":" . lstline
endfunction " >>>

" --ex_RemoveIFZero--
function! g:ex_RemoveIFZero() range " <<<
    let save_cursor = getpos(".")
    let save_line = getline(".")
    let cur_line = save_line

    let if_lnum = -1
    let else_lnum = -1
    let endif_lnum = -1

    " found '#if 0' first
    while match(cur_line, "#if.*0") == -1
        silent normal! [#
        let cur_line = getline(".")
        let lnum = line(".")
        if lnum == 0
            if match(cur_line, "#if.*0") == -1
                call g:ex_WarningMsg(" not #if 0 matched")
                return
            endif
        endif
    endwhile

    " record the line
    let if_lnum = line(".")
    silent normal! ]#
    let cur_line = getline(".")
    if match(cur_line, "#else") != -1
        let else_lnum = line(".")
        silent normal! ]#
        let endif_lnum = line(".")
    else
        let endif_lnum = line(".")
    endif

    " delete the if/else/endif
    if endif_lnum != -1
        silent exe "normal! ". endif_lnum ."G"
        silent normal! dd
    endif
    if else_lnum != -1
        silent exe "normal! ". else_lnum ."G"
        silent normal! dd
    endif
    if if_lnum != -1
        silent exe "normal! ". if_lnum ."G"
        silent normal! dd
    endif

    silent call setpos('.', save_cursor)
    silent call search(save_line, 'b')
    silent call cursor(line('.'), save_cursor[2])
endfunction " >>>

" --ex_InsertRemoveCmt--
function! g:ex_InsertRemoveCmt() range " <<<
    if (strpart(getline('.'),0,2) == "//")
        exec ":" . a:firstline . "," . a:lastline . "s\/^\\\/\\\/\/\/"
    else
        exec ":" . a:firstline . "," . a:lastline . "s\/^\/\\\/\\\/\/"
    endif
endfunction " >>>

" ------------------------
"  buffer functions
" ------------------------

" --ex_RecordCurrentBufNum--
" Record current buf num when leave
function! g:ex_RecordCurrentBufNum() " <<<
    let short_bufname = fnamemodify(bufname("%"),":p:t")
    if index( g:exUT_plugin_list, short_bufname ) == -1
        let s:ex_editbuf_num = bufnr('%')
    elseif short_bufname !=# "-MiniBufExplorer-"
        let s:ex_pluginbuf_num = bufnr('%')
    endif
endfunction " >>>

" --ex_UpdateCurrentBuffer--
"  Update current buffer
function! g:ex_UpdateCurrentBuffer() " <<<
    if exists(':UMiniBufExplorer')
        silent exe "UMiniBufExplorer"
    endif
endfunction " >>>

" --ex_GotoEditBuffer--
function! g:ex_GotoEditBuffer() " <<<
    " check and jump to the buffer first
    let winnum = bufwinnr(s:ex_editbuf_num)
    if winnr() != winnum
        exe winnum . 'wincmd w'
    endif
endfunction " >>>

" --ex_GotoPluginBuffer--
function! g:ex_GotoPluginBuffer() " <<<
    " check and jump to the buffer first
    let winnum = bufwinnr(s:ex_pluginbuf_num)
    if winnr() != winnum
        exe winnum . 'wincmd w'
    endif
endfunction " >>>

" --ex_GetEditBufferNum--
function! g:ex_GetEditBufferNum() " <<<
    return s:ex_editbuf_num
endfunction " >>>

" --ex_GotoLastEditBuffer--
function! g:ex_GotoLastEditBuffer() " <<<
    " check if buffer existed and listed
    let bufnr = bufnr("#")
    if buflisted(bufnr) && bufloaded(bufnr) && bufexists(bufnr)
        "silent exec "normal! M"
        silent exec bufnr."b!"
    else
        call g:ex_WarningMsg("Buffer: " .bufname(bufnr).  " can't be accessed.")
    endif
endfunction " >>>

" --ex_GotoLastEditBuffer--
function! g:ex_SwitchBuffer() " <<<
    " if current window is same as edit buffer window, jump to last edit window
    if winnr() == bufwinnr(s:ex_editbuf_num)
        call g:ex_GotoPluginBuffer()
    else
        call g:ex_GotoEditBuffer()
    endif
endfunction " >>>

" --ex_Kwbd--
" VimTip #1119: How to use Vim like an IDE
" delete the buffer; keep windows; create a scratch buffer if no buffers left 
" Using this Kwbd function (:call Kwbd(1)) will make Vim behave like an IDE; or maybe even better. 
function g:ex_Kwbd(kwbdStage) " <<<
    if(a:kwbdStage == 1) 
        if(!buflisted(winbufnr(0))) 
            bd! 
            return 
        endif 
        let g:kwbdBufNum = bufnr("%") 
        let g:kwbdWinNum = winnr() 
        windo call g:ex_Kwbd(2) 
        execute "normal " . g:kwbdWinNum . "" 
        let g:buflistedLeft = 0 
        let g:bufFinalJump = 0 
        let l:nBufs = bufnr("$") 
        let l:i = 1 
        while(l:i <= l:nBufs) 
            if(l:i != g:kwbdBufNum) 
                if(buflisted(l:i)) 
                    let g:buflistedLeft = g:buflistedLeft + 1 
                else 
                    if(bufexists(l:i) && !strlen(bufname(l:i)) && !g:bufFinalJump) 
                        let g:bufFinalJump = l:i 
                    endif 
                endif 
            endif 
            let l:i = l:i + 1 
        endwhile 
        if(!g:buflistedLeft) 
            if(g:bufFinalJump) 
                windo if(buflisted(winbufnr(0))) | execute "b! " . g:bufFinalJump | endif 
            else 
                enew 
                let l:newBuf = bufnr("%") 
                windo if(buflisted(winbufnr(0))) | execute "b! " . l:newBuf | endif 
            endif 
            execute "normal " . g:kwbdWinNum . "" 
        endif 
        if(buflisted(g:kwbdBufNum) || g:kwbdBufNum == bufnr("%")) 
            execute "bd! " . g:kwbdBufNum 
        endif 
        if(!g:buflistedLeft) 
            set buflisted 
            set bufhidden=delete 
            set buftype=nofile 
            setlocal noswapfile 
            normal athis is the scratch buffer 
        endif 
    else 
        if(bufnr("%") == g:kwbdBufNum) 
            let prevbufvar = bufnr("#") 
            if(prevbufvar > 0 && buflisted(prevbufvar) && prevbufvar != g:kwbdBufNum) 
                b # 
            else 
                bn 
            endif 
        endif 
    endif 
endfunction  " >>>


" ------------------------
"  file functions
" ------------------------

" --ex_ConvertFileName--
" Convert full file name into the format: file_name (directory)
function! g:ex_ConvertFileName(full_file_name) " <<<
    return fnamemodify( a:full_file_name, ":t" ) . ' (' . fnamemodify( a:full_file_name, ":h" ) . ')'    
endfunction ">>>

" --ex_GetFullFileName--
" Get full file name from converted format
function! g:ex_GetFullFileName(converted_line) " <<<
    if match(a:converted_line, '^\S\+\s(\S\+)$') == -1
        call g:ex_WarningMsg('format is wrong')
        return
    endif
    let idx_space = stridx(a:converted_line, ' ')
    let simple_file_name = strpart(a:converted_line, 0, idx_space)
    let idx_bracket_first = stridx(a:converted_line, '(')
    let file_path = strpart(a:converted_line, idx_bracket_first+1)
    let idx_bracket_last = stridx(file_path, ')')
    return strpart(file_path, 0, idx_bracket_last) . '\' . simple_file_name
endfunction " >>>

" --ex_MatchTagFile()--
" Match tag and find file if it has
function! g:ex_MatchTagFile( tag_file_list, file_name ) " <<<
    " if we can use PWD find file, use it first
    if exists('g:exES_PWD')
        let full_file_name = substitute(g:exES_PWD,'\','',"g") . substitute(a:file_name,'\.\\','\\',"g")
        if findfile(full_file_name) != ''
            return simplify(full_file_name)
        endif
    endif

    let full_file_name = ''
    for tag_file in a:tag_file_list
        let tag_path = strpart( tag_file, 0, strridx(tag_file, '\') )
        let full_file_name = tag_path . a:file_name
        if findfile(full_file_name) != ''
            break
        endif
        let full_file_name = ''
    endfor

    if full_file_name == ''
        call g:ex_WarningMsg( a:file_name . ' not found' )
    endif

    return simplify(full_file_name)
endfunction " >>>

" --ex_GetFileFilterPattern--
function! g:ex_GetFileFilterPattern(filter) " <<<
    let filter_list = split(a:filter,' ')
    let filter_pattern = '\V'
    for filter in filter_list
        let filter_pattern = filter_pattern . '.' . '\<' . filter . '\>\$\|'
    endfor
    return strpart(filter_pattern, 0, strlen(filter_pattern)-2)
endfunction " >>>

" --ex_BrowseWithEmtpy--
function! g:ex_BrowseWithEmtpy(dir, filter) " <<<
    " get short_dir
    "let short_dir = strpart( a:dir, strridx(a:dir,'\')+1 )
    let short_dir = fnamemodify( a:dir, ":t" )
    if short_dir == ''
        let short_dir = a:dir
    endif

    " write space
    let space = ''
    let list_idx = 0
    let list_last = len(s:ex_level_list)-1
    for level in s:ex_level_list
        if level.is_last != 0 && list_idx != list_last
            let space = space . '  '
        else
            let space = space . ' |'
        endif
        let list_idx += 1
    endfor
    let space = space.'-'

    " get end_fold
    let end_fold = ''
    let rev_list = reverse(copy(s:ex_level_list))
    for level in rev_list
        if level.is_last != 0
            let end_fold = end_fold . ' }'
        else
            break
        endif
    endfor

    " judge if it is a dir
    if isdirectory(a:dir) == 0
        " put it
        " let file_type = strpart( short_dir, strridx(short_dir,'.')+1, 1 )
        let file_type = strpart( fnamemodify( short_dir, ":e" ), 0, 1 )
        silent put = space.'['.file_type.']'.short_dir  . end_fold
        " if file_end enter a new line for it
        if end_fold != ''
            let end_space = strpart(space,0,strridx(space,'-')-1)
            let end_space = strpart(end_space,0,strridx(end_space,'|')+1)
            silent put = end_space " . end_fold
        endif
        return
    else
        " split the first level to file_list
        let file_list = split(globpath(a:dir,'*'),'\n')

        " first sort the list as we want (file|dir )
        let list_idx = 0
        let list_last = len(file_list)-1
        let list_count = 0
        while list_count <= list_last
            if isdirectory(file_list[list_idx]) == 0 " move the file to the end of the list
                if match(file_list[list_idx],a:filter) == -1
                    silent call remove(file_list,list_idx)
                    let list_idx -= 1
                else
                    let file = remove(file_list,list_idx)
                    silent call add(file_list, file)
                    let list_idx -= 1
                endif
            endif
            " ++++++++++++++++++++++++++++++++++
            " if isdirectory(file_list[list_idx]) != 0 " move the dir to the end of the list
            "     let dir = remove(file_list,list_idx)
            "     silent call add(file_list, dir)
            "     let list_idx -= 1
            " else " filter file
            "     if match(file_list[list_idx],a:filter) == -1
            "         silent call remove(file_list,list_idx)
            "         let list_idx -= 1
            "     endif
            " endif
            " ++++++++++++++++++++++++++++++++++

            let list_idx += 1
            let list_count += 1
        endwhile

        "silent put = strpart(space, 0, strridx(space,'\|-')+1)
        if len(file_list) == 0 " if it is a empty directory
            if end_fold == ''
                " if dir_end enter a new line for it
                let end_space = strpart(space,0,strridx(space,'-'))
            else
                " if dir_end enter a new line for it
                let end_space = strpart(space,0,strridx(space,'-')-1)
                let end_space = strpart(end_space,0,strridx(end_space,'|')+1)
            endif
            let end_fold = end_fold . ' }'
            silent put = space.'[F]'.short_dir . ' {' . end_fold
            silent put = end_space
        else
            silent put = space.'[F]'.short_dir . ' {'
        endif
        silent call add(s:ex_level_list, {'is_last':0,'short_dir':short_dir})
    endif

    " ECHO full_path for this level
    " ++++++++++++++++++++++++++++++++++
    " let full_path = ''
    " for level in s:ex_level_list
    "     let full_path = level.short_dir.'/'.full_path
    " endfor
    " echon full_path."\r"
    " ++++++++++++++++++++++++++++++++++

    " recuseve browse list
    let list_idx = 0
    let list_last = len(file_list)-1
    for dir in file_list
        if list_idx == list_last
            let s:ex_level_list[len(s:ex_level_list)-1].is_last = 1
        endif
        call g:ex_BrowseWithEmtpy(dir,a:filter)
        let list_idx += 1
    endfor
    silent call remove( s:ex_level_list, len(s:ex_level_list)-1 )
endfunction " >>>

" --ex_SetLevelList()
function! g:ex_SetLevelList( line_num, by_next_line ) " <<<
    if len(s:ex_level_list)
        silent call remove(s:ex_level_list, 0, len(s:ex_level_list)-1)
    endif

    " for the clear method
    if a:line_num == -1
        return
    endif

    let idx = -1
    let cur_line = ''
    if a:by_next_line == 1
        let cur_line = getline(a:line_num+1)
        let idx = strridx(cur_line, '|') -2
    else
        let cur_line = getline(a:line_num)
        let idx = strridx(cur_line, '|')
    endif
    let cur_line = strpart(cur_line, 1, idx)

    let len = strlen(cur_line)
    let idx = 0
    while idx <= len
        if cur_line[idx] == '|'
            silent call add(s:ex_level_list, {'is_last':0,'short_dir':''})
        else
            silent call add(s:ex_level_list, {'is_last':1,'short_dir':''})
        endif
        let idx += 2
    endwhile

    echo s:ex_level_list
endfunction " >>>

" --ex_FileNameSort--
function! g:ex_FileNameSort( i1, i2 ) " <<<
    return a:i1 ==? a:i2 ? 0 : a:i1 >? a:i2 ? 1 : -1
endfunction " >>>

" --ex_Browse--
function! g:ex_Browse(dir, filter) " <<<
    " get short_dir
    " let short_dir = strpart( a:dir, strridx(a:dir,'\')+1 )
    let short_dir = fnamemodify( a:dir, ":t" )

    " if directory
    if isdirectory(a:dir) == 1
        " split the first level to file_list
        let file_list = split(globpath(a:dir,'*'),'\n')
        silent call sort( file_list, "g:ex_FileNameSort" )

        " sort and filter the list as we want (file|dir )
        let list_idx = 0
        let list_last = len(file_list)-1
        let list_count = 0
        while list_count <= list_last
            if isdirectory(file_list[list_idx]) == 0 " move the file to the end of the list
                if match(file_list[list_idx],a:filter) == -1
                    silent call remove(file_list,list_idx)
                    let list_idx -= 1
                else
                    let file = remove(file_list,list_idx)
                    silent call add(file_list, file)
                    let list_idx -= 1
                endif
            endif
            " ++++++++++++++++++++++++++++++++++
            "if isdirectory(file_list[list_idx]) != 0 " move the dir to the end of the list
            "    let dir = remove(file_list,list_idx)
            "    silent call add(file_list, dir)
            "    let list_idx -= 1
            "else " filter file
            "    if match(file_list[list_idx],a:filter) == -1
            "        silent call remove(file_list,list_idx)
            "        let list_idx -= 1
            "    endif
            "endif
            " ++++++++++++++++++++++++++++++++++

            let list_idx += 1
            let list_count += 1
        endwhile

        silent call add(s:ex_level_list, {'is_last':0,'short_dir':short_dir})
        " recuseve browse list
        let list_last = len(file_list)-1
        let list_idx = list_last
        let s:ex_level_list[len(s:ex_level_list)-1].is_last = 1
        while list_idx >= 0
            if list_idx != list_last
                let s:ex_level_list[len(s:ex_level_list)-1].is_last = 0
            endif
            if g:ex_Browse(file_list[list_idx],a:filter) == 1 " if it is empty
                silent call remove(file_list,list_idx)
                let list_last = len(file_list)-1
            endif
            let list_idx -= 1
        endwhile

        silent call remove( s:ex_level_list, len(s:ex_level_list)-1 )

        if len(file_list) == 0
            return 1
        endif
    endif

    " write space
    let space = ''
    let list_idx = 0
    let list_last = len(s:ex_level_list)-1
    for level in s:ex_level_list
        if level.is_last != 0 && list_idx != list_last
            let space = space . '  '
        else
            let space = space . ' |'
        endif
        let list_idx += 1
    endfor
    let space = space.'-'

    " get end_fold
    let end_fold = ''
    let rev_list = reverse(copy(s:ex_level_list))
    for level in rev_list
        if level.is_last != 0
            let end_fold = end_fold . ' }'
        else
            break
        endif
    endfor

    " judge if it is a dir
    if isdirectory(a:dir) == 0
        " if file_end enter a new line for it
        if end_fold != ''
            let end_space = strpart(space,0,strridx(space,'-')-1)
            let end_space = strpart(end_space,0,strridx(end_space,'|')+1)
            silent put! = end_space " . end_fold
        endif
        " put it
        " let file_type = strpart( short_dir, strridx(short_dir,'.')+1, 1 )
        let file_type = strpart( fnamemodify( short_dir, ":e" ), 0, 1 )
        silent put! = space.'['.file_type.']'.short_dir . end_fold
        return 0
    else

        "silent put = strpart(space, 0, strridx(space,'\|-')+1)
        if len(file_list) == 0 " if it is a empty directory
            if end_fold == ''
                " if dir_end enter a new line for it
                let end_space = strpart(space,0,strridx(space,'-'))
            else
                " if dir_end enter a new line for it
                let end_space = strpart(space,0,strridx(space,'-')-1)
                let end_space = strpart(end_space,0,strridx(end_space,'|')+1)
            endif
            let end_fold = end_fold . ' }'
            silent put! = end_space
            silent put! = space.'[F]'.short_dir . ' {' . end_fold
        else
            silent put! = space.'[F]'.short_dir . ' {'
        endif
        if list_last == -1 " if len of ex_level_list is 0
            silent put! = ''
        endif
    endif
    return 0

    " ECHO full_path for this level
    " ++++++++++++++++++++++++++++++++++
    " let full_path = ''
    " for level in s:ex_level_list
    "     let full_path = level.short_dir.'/'.full_path
    " endfor
    " echomsg full_path . "\r"
    " ++++++++++++++++++++++++++++++++++
endfunction " >>>

" --ex_GetFoldLevel--
function! g:ex_QuickFileJump() " <<<
    " make the gf go everywhere in the project
    if exists( 'g:exES_PWD' )
        let tmp_reg = @t
        let save_pos = getpos(".")
        normal! "tyiW
        silent call setpos(".", save_pos )
        let file_name = substitute( @t, '\("\|<\|>\)', '', "g" )
        let @t = tmp_reg
        echomsg "searching file: " . file_name
        let path = escape(g:exES_PWD, " ") . "/**;"
        let full_path_file = findfile( file_name, path ) 

        " if we found the file
        if full_path_file != ""
            silent exec "e " . full_path_file 
            echon full_path_file . "\r"
        else
            call g:ex_WarningMsg("file not found")
        endif
    else
        normal! gf
    endif
endfunction " >>>

" ------------------------
"  fold functions
" ------------------------

" --ex_GetFoldLevel--
function! g:ex_GetFoldLevel(line_num) " <<<
    let cur_line = getline(a:line_num)
    let cur_line = strpart(cur_line,0,strridx(cur_line,'|')+1)
    let str_len = strlen(cur_line)
    return str_len/2
endfunction " >>>

" --ex_FoldText() --
function! g:ex_FoldText() " <<<
    let line = getline(v:foldstart)
    let line = substitute(line,'\[F\]\(.\{-}\) {.*','\[+\]\1 ','')
    return line
    " let line = getline(v:foldstart)
    " let line = strpart(line, 0, strridx(line,'|')+1)
    " let line = line . '+'
    " return line
endfunction ">>>

" ------------------------
"  jump functions
" ------------------------

" --ex_Goto--
" Goto the position by file name and search pattern
function! g:ex_GotoSearchPattern(full_file_name, search_pattern) " <<<
    " check and jump to the buffer first
    call g:ex_GotoEditBuffer()

    " start jump
    let file_name = escape(a:full_file_name, ' ')
    exe 'silent e ' . file_name

    " if search_pattern is digital, just set pos of it
    let line_num = strpart(a:search_pattern, 2, strlen(a:search_pattern)-4)
    let line_num = matchstr(line_num, '^\d\+$')
    if line_num
        call cursor(eval(line_num), 1)
    elseif search(a:search_pattern, 'w') == 0
        call g:ex_WarningMsg('search pattern not found')
        return 0
    endif

    " set the text at the middle
    exe 'normal! zz'

    return 1
endfunction " >>>

" --ex_GotoExCommand--
" Goto the position by file name and search pattern
function! g:ex_GotoExCommand(full_file_name, ex_cmd) " <<<
    " check and jump to the buffer first
    call g:ex_GotoEditBuffer()

    " start jump
    let file_name = escape(a:full_file_name, ' ')
    if bufnr('%') != bufnr(file_name)
        exe 'silent e ' . file_name
    endif

    " cursor jump
    try
        silent exe a:ex_cmd
    catch /^Vim\%((\a\+)\)\=:E/
        " if ex_cmd is not digital, try jump again manual
        if match( a:ex_cmd, '^\/\^' ) != -1
            let pattern = strpart(a:ex_cmd, 2, strlen(a:ex_cmd)-4)
            let pattern = '\V\^' . pattern . (pattern[len(pattern)-1] == '$' ? '\$' : '')
            if search(pattern, 'w') == 0
                call g:ex_WarningMsg('search pattern not found: ' . pattern)
                return 0
            endif
        endif
    endtry

    " set the text at the middle
    exe 'normal! zz'

    return 1
endfunction " >>>

" --ex_GotoTagNumber--
function! g:ex_GotoTagNumber(tag_number) " <<<
    " check and jump to the buffer first
    call g:ex_GotoEditBuffer()

    silent exec a:tag_number . "tr!"

    " set the text at the middle
    exe 'normal! zz'
endfunction " >>>

" --ex_GotoPos--
" Goto the pos by position list
function! g:ex_GotoPos(poslist) " <<<
    " check and jump to the buffer first
    call g:ex_GotoEditBuffer()

    " TODO must have buffer number or buffer name
    call setpos('.', a:poslist)

    " set the text at the middle
    exe 'normal! zz'
endfunction " >>>

" ------------------------
"  make functions
" ------------------------

" --ex_GCCMake()--
function! g:ex_GCCMake(args) " <<<
    " save all file for compile first
    silent exec "wa!"

    let entry_file = glob('gcc_entry*.mk') 
    if entry_file != ''
        exec "!make -f" . entry_file . " " . a:args
    else
        call g:ex_WarningMsg("entry file not found")
    endif
endfunction " >>>

" --ex_ShaderMake()--
function! g:ex_ShaderMake(args) " <<<
    " save all file for compile first
    silent exec "wa!"

    let entry_file = glob('shader_entry*.mk') 
    if entry_file != ''
        exec "!make -f" . entry_file . " " . a:args
    else
        call g:ex_WarningMsg("entry file not found")
    endif
endfunction " >>>

" --ex_VCMake()-- 
function! g:ex_VCMake(cmd, config) " <<<
    " save all file for compile first
    silent exec "wa!"

    let make_vs = glob('make_vs.bat') 
    if make_vs != ''
        if exists('g:exES_Solution')
            let escape_idx = stridx(a:cmd, '/')
            let prj_name = ''
            let cmd = a:cmd

            " parse project
            if escape_idx != -1
                let prj_name = strpart(a:cmd, 0, escape_idx)
                let cmd = strpart(a:cmd, escape_idx+1)
            endif

            " redefine cmd
            if cmd == "all"
                let cmd = "Build"
            elseif cmd == "rebuild"
                let cmd = "Rebuild"
            elseif cmd == "clean-all"
                let cmd = "Clean"
            else
                call g:ex_WarningMsg("command: ".cmd."not found")
                return
            endif

            " exec make_vs.bat
            exec "!make_vs ".cmd.' '.g:exES_Solution.' '.a:config.' '.prj_name
        else
            call g:ex_WarningMsg("solution not found")
        endif
    else
        call g:ex_WarningMsg("make_vs.bat not found")
    endif
endfunction " >>>

" --ex_UpdateVimFiles()--
"  type: ID,symbol,tag,none=all
function! g:ex_UpdateVimFiles( type ) " <<<
    " exec bat
    let quick_gen_bat = glob('quick_gen_project*.bat') 
    if a:type == ""
        if quick_gen_bat != ''
            silent exec "cscope kill " . g:exES_Cscope
            silent exec "!" . quick_gen_bat
            silent exec "cscope add " . g:exES_Cscope
        else
            call g:ex_WarningMsg("quick_gen_project*.bat not found")
        endif
    elseif a:type == "ID"
        silent exec "!" . quick_gen_bat . " id"
    elseif a:type == "symbol"
        silent exec "!" . quick_gen_bat . " symbol"
    elseif a:type == "inherits"
        silent exec "!" . quick_gen_bat . " inherits"
    elseif a:type == "tag"
        silent exec "!" . quick_gen_bat . " tag"
    elseif a:type == "cscope"
        silent exec "cscope kill " . g:exES_Cscope
        silent exec "!" . quick_gen_bat . " cscope"
        silent exec "cscope add " . g:exES_Cscope
    else
        call g:ex_WarningMsg("do not found update-type: " . a:type )
    endif
endfunction " >>>

" --ex_Debug()--
function! g:ex_Debug( exe_name ) " <<<
    if glob(a:exe_name) == ''
        call g:ex_WarningMsg('file: ' . a:exe_name . ' not found')
    else
        silent exec '!insight ' . a:exe_name
    endif
endfunction " >>>

" ------------------------
"  Hightlight functions
" ------------------------

" --ex_HighlightConfirmLine--
" hightlight confirm line
function! g:ex_HighlightConfirmLine() " <<<
    " Clear previously selected name
    match none
    " Highlight the current line
    let pat = '/\%' . line('.') . 'l.*/'
    exe 'match ex_SynConfirmLine ' . pat
endfunction " >>>

" --ex_HighlightSelectLine--
" hightlight select line
function! g:ex_HighlightSelectLine() " <<<
    " Clear previously selected name
    2match none
    " Highlight the current line
    let pat = '/\%' . line('.') . 'l.*/'
    exe '2match ex_SynSelectLine ' . pat
endfunction " >>>

" --ex_HighlightObjectLine--
" hightlight object line
function! g:ex_HighlightObjectLine() " <<<
    " Clear previously selected name
    3match none
    " Highlight the current line
    let pat = '/\%' . line('.') . 'l.*/'
    exe '3match ex_SynObjectLine ' . pat
endfunction " >>>

" --ex_ClearObjectHighlight--
"  clear the object line hight light
function! g:ex_ClearObjectHighlight() " <<<
    " Clear previously selected name
    3match none
endfunction " >>>

" --ex_Highlight_Normal--
" hightlight match_nr
function! g:ex_Highlight_Normal(match_nr) " <<<
    let cur_line = line(".")
    let cur_col = col(".")
    " Clear previously selected name
    silent exe a:match_nr . 'match none'

    let reg_h = @h
    exe 'normal! "hyiw'
    if @h == s:ex_HighLightText[a:match_nr]
        call g:ex_HighlightCancle(a:match_nr)
    else
        exe a:match_nr . 'match ex_SynHL' . a:match_nr . ' ' . '/\<'.@h.'\>/'
        let s:ex_HighLightText[a:match_nr] = @h
    endif
    let @h = reg_h
    silent call cursor(cur_line, cur_col)
endfunction " >>>

" --ex_Highlight_Text--
" hightlight match_nr with text
function! g:ex_Highlight_Text(match_nr, args) " <<<
    let cur_line = line(".")
    let cur_col = col(".")
    " Clear previously selected name
    silent exe a:match_nr . 'match none'

    exe a:match_nr . 'match ex_SynHL' . a:match_nr . ' ' . '"' . a:args . '"'
    if a:args == s:ex_HighLightText[a:match_nr]
        call g:ex_HighlightCancle(a:match_nr)
    else
        let s:ex_HighLightText[a:match_nr] = a:args
        silent call cursor(cur_line, cur_col)
    endif
endfunction " >>>

" --ex_Highlight_Visual--
" hightlight match_nr
function! g:ex_Highlight_Visual(match_nr) " <<<
    let cur_line = line(".")
    let cur_col = col(".")
    " Clear previously selected name
    silent exe a:match_nr . 'match none'
    let line_start = line("'<")
    let line_end = line("'>")

    " if in the same line
    let pat = '//'
    if line_start == line_end
        let sl = line_start-1
        let sc = col("'<")-1
        let el = line_end+1
        let ec = col("'>")+1
        let pat = '/\%>'.sl.'l'.'\%>'.sc.'v'.'\%<'.el.'l'.'\%<'.ec.'v/'
    else
        let sl = line_start-1
        let el = line_end+1
        let pat = '/\%>'.sl.'l'.'\%<'.el.'l/'
    endif
    if pat == s:ex_HighLightText[a:match_nr]
        call g:ex_HighlightCancle(a:match_nr)
    else
        exe a:match_nr . 'match ex_SynHL' . a:match_nr . ' ' . pat
        let s:ex_HighLightText[a:match_nr] = pat
    endif
    silent call cursor(cur_line, cur_col)
endfunction " >>>

" --ex_HighlightCancle--
" Cancle highlight
function! g:ex_HighlightCancle(match_nr) " <<<
    let cur_line = line(".")
    let cur_col = col(".")
    if a:match_nr == 0
        1match none
        2match none
        3match none
        let s:ex_HighLightText[1] = ''
        let s:ex_HighLightText[2] = ''
        let s:ex_HighLightText[3] = ''
    else
        silent exe a:match_nr . 'match none'
        let s:ex_HighLightText[a:match_nr] = ''
    endif
    silent call cursor(cur_line, cur_col)
endfunction " >>>

" ------------------------
"  Inherits functions
" ------------------------

" --ex_GenInheritsDot--
"
function! g:ex_GenInheritsDot( pattern, gen_method ) " <<<
    " find inherits file
    if exists( g:exES_Inherits )
        let inherits_file = g:exES_Inherits
    else
        let inherits_file = "./_vimfiles/inherits"
    endif

    " create inherit dot file path
    let inherit_directory_path = g:exES_PWD.'/'.g:exES_vimfile_dir.'/_hierarchies/' 
    if finddir(inherit_directory_path) == ''
        silent call mkdir(inherit_directory_path)
    endif
    let pattern_fname = substitute( a:pattern, "[^0-9A-Za-z_:]", "", "g" ) . "_" . a:gen_method
    let inherits_dot_file = inherit_directory_path . pattern_fname . ".dot"

    " read the inherits file
    let file_list = readfile( inherits_file )

    " init value
    let s:pattern_list = []
    let inherits_list = []

    " judge method
    if a:gen_method == "all"
        let parent_pattern = "->.*" . a:pattern
        let children_pattern = a:pattern . ".*->"

        " first filter
        let parent_inherits_list = filter( copy(file_list), 'v:val =~ parent_pattern' )
        let inherits_list += parent_inherits_list
        let children_inherits_list = filter( copy(file_list), 'v:val =~ children_pattern' )
        let inherits_list += children_inherits_list

        " processing inherits
        let inherits_list += s:ex_RecursiveGetParent( parent_inherits_list, file_list )
        let inherits_list += s:ex_RecursiveGetChildren( children_inherits_list, file_list )
    else
        if a:gen_method == "parent"
            let pattern = "->.*" . a:pattern
        elseif a:gen_method == "children"
            let pattern = a:pattern . ".*->"
        endif

        " first filter
        let inherits_list += filter( copy(file_list), 'v:val =~ pattern' )

        " processing inherits
        if a:gen_method == "parent"
            let inherits_list += s:ex_RecursiveGetParent( inherits_list, file_list )
        elseif a:gen_method == "children"
            let inherits_list += s:ex_RecursiveGetChildren( inherits_list, file_list )
        endif
    endif

    " add dot gamma
    let inherits_list = ["digraph INHERITS {", "rankdir=LR;"] + inherits_list
    let inherits_list += ["}"]
    unlet s:pattern_list

    " write file
    call writefile(inherits_list, inherits_dot_file, "b")
    let dot_cmd = "!dot " . inherits_dot_file . " -Tpng -o" . inherit_directory_path . pattern_fname . ".png"
    silent exec dot_cmd
endfunction " >>>

" --ex_RecursiveGetChildren--
function! s:ex_RecursiveGetChildren(inherits_list, file_list) " <<<
    let result_list = []
    for inherit in a:inherits_list
        " change to parent pattern
        let pattern = strpart( inherit, stridx(inherit,"->")+3 ) . ' ->'

        " skip parsed pattern
        if index( s:pattern_list, pattern ) >= 0
            continue
        endif
        call add( s:pattern_list, pattern )

        " add children list
        let children_list = filter( copy(a:file_list), 'v:val =~# pattern' )
        let result_list += children_list 

        " recursive the children
        let result_list += s:ex_RecursiveGetChildren( children_list, a:file_list ) 
    endfor
    return result_list
endfunction " >>>

" --ex_RecursiveGetParent--
function! s:ex_RecursiveGetParent(inherits_list, file_list) " <<<
    let result_list = []
    for inherit in a:inherits_list
        " change to child pattern
        let pattern =  '-> ' . strpart( inherit, 0, stridx(inherit,"->")-1 )

        " skip parsed pattern
        if index( s:pattern_list, pattern ) >= 0
            continue
        endif
        call add( s:pattern_list, pattern )

        " add pattern list
        let parent_list = filter( copy(a:file_list), 'v:val =~# pattern' )
        let result_list += parent_list 

        " recursive the parent
        let result_list += s:ex_RecursiveGetParent( parent_list, a:file_list ) 
    endfor
    return result_list
endfunction " >>>

" ------------------------
"  Debug functions
" ------------------------

" --ex_WarningMsg--
" Display a message using WarningMsg highlight group
function! g:ex_WarningMsg(msg) " <<<
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction " >>>

" fix vim bug.
" when you use clipboard=unnamed, and you have two vim-windows, visual-copy 
" in window-1, then visual-copy in window-2, then visual-paste again. it is wrong
" FIXME: this will let the "ap useless
function! g:ex_VisualPasteFixed() " <<<
    silent call getreg('*')
    " silent normal! gvpgvy " <-- this let you be the win32 copy/paste style
    silent normal! gvp
endfunction " >>>

finish
" vim: set foldmethod=marker foldmarker=<<<,>>> foldlevel=1:
