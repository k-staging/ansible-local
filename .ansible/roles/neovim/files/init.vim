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
nmap <Tab> <Plug>AirlineSelectPrevTab
nmap <S-Tab> <Plug>AirlineSelectNextTab
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
nnoremap <silent> <C-p>  :<C-u>FzfPreviewProjectFilesRpc<CR>
nnoremap <silent> gs  :<C-u>FzfPreviewGitStatusRpc<CR>
nnoremap <silent> gl  :<C-u>FzfPreviewGitLogsRpc<CR>
nnoremap <silent> ga  :<C-u>FzfPreviewGitActionsRpc<CR>
nnoremap <silent> gr  :<C-u>FzfPreviewProjectGrepRpc --add-fzf-arg=--exact --add-fzf-arg=--no-sort<Space>
xnoremap gr  "sy:FzfPreviewProjectGrepRpc --add-fzf-arg=--exact --add-fzf-arg=--no-sort<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
let g:fzf_preview_custom_processes = {
            \ 'open-file': {
            \     'ctrl-o': 'FzfPreviewOpenFileCtrlO',
            \     'ctrl-f': 'FzfPreviewOpenFileCtrlQ',
            \     'ctrl-t': 'FzfPreviewOpenFileCtrlT',
            \     'ctrl-v': 'FzfPreviewOpenFileCtrlV',
            \     'ctrl-x': 'FzfPreviewOpenFileCtrlX',
            \     'enter': 'FzfPreviewOpenFileEnter'
            \ },
            \ 'register': {
            \     'enter': 'FzfPreviewRegisterEnter'
            \ }
\ }

" Neovim lsp
lua << EOF
local nvim_lsp = require('lspconfig')
local servers  = { 'bashls', 'cssmodules_ls', 'gopls', 'graphql', 'pylsp', 'solargraph', 'vimls' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {}
end

require('lspconfig').sqls.setup{
    on_attach = function(client)
        client.resolved_capabilities.execute_command = true
        client.commands = require('sqls').commands

        require('sqls').setup{}
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
function goimports(timeout_ms)
  local context = { only = { "source.organizeImports" } }
  vim.validate { context = { context, "t", true } }

  local params = vim.lsp.util.make_range_params()
  params.context = context

  -- See the implementation of the textDocument/codeAction callback
  -- (lua/vim/lsp/handler.lua) for how to do this properly.
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
  if not result or next(result) == nil then return end
  local actions = result[1].result
  if not actions then return end
  local action = actions[1]

  -- textDocument/codeAction can return either Command[] or CodeAction[]. If it
  -- is a CodeAction, it can have either an edit, a command or both. Edits
  -- should be executed first.
  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
  else
    vim.lsp.buf.execute_command(action)
  end
end
EOF
nnoremap <C-o> :<C-u>lua vim.lsp.buf.definition()<CR>
autocmd BufWritePre *.go call execute('lua vim.lsp.buf.formatting_sync()')
autocmd BufWritePre *.go lua goimports(1000)

" vim-startify
let g:startify_change_to_dir = 0
let g:startify_session_autoload = 1
let g:startify_session_persistence = 1
let g:startify_session_dir = '~/.nvim/session'
let g:startify_session_number = 5
let g:startify_custom_header = [
  \ '    ============================================',
  \ '     Neovim ( v0.6.0 ) ',
  \ '    ============================================',
  \]
let g:startify_lists = [
          \ { 'type': 'sessions',  'header': ['    Sessions'] },
          \ { 'type': 'dir',       'header': ['    MRU '. getcwd()] },
          \ ]

" fern.vim
let g:fern#default_hidden=1
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
