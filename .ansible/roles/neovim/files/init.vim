" Colorsheme
syntax on
set background=dark
set t_Co=256
colorscheme gruvbox

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#close_symbol = '×'
let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#virtualenv#enabled = 1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
nmap <C-t> <Plug>AirlineSelectPrevTab
nmap <S-t> <Plug>AirlineSelectNextTab
nmap <C-c> :tablast <bar> tabnew<CR>

" Gitgutter
set  signcolumn=yes

" Deol.nvim
let g:deol#shell_history_path='~/.bash_history'
tnoremap <Esc> <C-\><C-n>
nnoremap <C-d> :<C-u>Deol -split=vertical<CR>
tnoremap <Esc> <C-W>N
tnoremap <Esc><Esc> <C-W>N
set timeout timeoutlen=1000
set ttimeout ttimeoutlen=100

" fzf.vim
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'source': 'ag --hidden --ignore .git -g ""'}), <bang>0)
command! -bang -nargs=* Ag
  \ call fzf#vim#grep(
  \   'ag --column --color --hidden --ignore .git '.shellescape(<q-args>), 0,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%', '?'),
  \   <bang>0)
" fzf.vim
" Ag -> ctrl-a -> ctrl-q -> Enter
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction
let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'

" Neovim lsp
lua << EOF
local nvim_lsp = require('lspconfig')
local servers  = { 'bashls', 'gopls', 'graphql', 'pylsp', 'solargraph', 'terraformls', 'tsserver', 'vimls', 'vuels' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {}
end
require'lspconfig'.sqls.setup{
  on_attach = function(client)
      client.resolved_capabilities.execute_command = true
      require'sqls'.setup{
        cmd = { "sqls" },
        settings = {
            sqls = {
            }
        }
      }
  end
}

require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  resolve_timeout = 800;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = {
    border = { '', '' ,'', ' ', '', '', '', ' ' }, -- the border option is the same as `|help nvim_open_win|`
    winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
    max_width = 120,
    min_width = 60,
    max_height = math.floor(vim.o.lines * 0.3),
    min_height = 1,
  };

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    vsnip = true;
    ultisnips = true;
    luasnip = true;
  };
}
EOF
nnoremap <C-o> :<C-u>lua vim.lsp.buf.definition()<CR>

" vim-startify
let g:startify_change_to_dir = 0
let g:startify_session_autoload = 1
let g:startify_session_persistence = 1
let g:startify_session_dir = '~/.nvim/session'
let g:startify_session_number = 5
let g:startify_custom_header = [
  \ '    ============================================',
  \ '     Neovim ( v0.5.0 ) ',
  \ '    ============================================',
  \]
let g:startify_lists = [
          \ { 'type': 'sessions',  'header': ['    Sessions'] },
          \ { 'type': 'dir',       'header': ['    MRU '. getcwd()] },
          \ ]

" fern.vim
nnoremap <C-n> :Fern . -reveal=% -drawer -toggle -width=40<CR>

" universal ctags
set tags+=.tags
let g:auto_ctags = 1
let g:auto_ctags_tags_name = '.tags'
let g:auto_ctags_tags_args = '--tag-relative --recurse --sort=yes'
let g:auto_ctags_directory_list = ['.git']
nnoremap <F3> :<C-u>tab stj <C-R>=expand('<cword>')<CR><CR>

" tagbar
nnoremap <S-o> :TagbarToggle<CR>

" キーバインド変更
nnoremap j gj
nnoremap k gk
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" インデント関連の設定
set tabstop=8
set softtabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set backspace=indent,eol,start

" その他
set number
set splitright
set hls
set whichwrap=b,s,h,l,<,>,[,]
set cursorline
set cursorcolumn
set clipboard+=unnamedplus
set clipboard+=unnamed
set switchbuf+=usetab,newtab
set wildignore=assets
set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" 前回開いた行数から再開する
augroup vimrcEx
  au BufRead * if line("'\"") > 0 && line("'\"") <= line("$") |
  \ exe "normal g`\"" | endif
augroup END

" wsl用設定
if system('uname -a | grep microsoft') != ''
  augroup Yank
    au!
    autocmd TextYankPost * :call system('win32yank.exe -i', @")
  augroup END
  noremap <silent> p :call setreg('"',system('win32yank.exe -o'))<CR>""p
endif

