## vim-clap-hoogle

[vim-clap](https://github.com/liuchengxu/vim-clap) local [hoogle](https://github.com/ndmitchell/hoogle) provider


### Setup
- Install [hoogle locally](https://github.com/ndmitchell/hoogle/blob/master/docs/Install.md) and generate a database

- Install vim-clap and this provider:
    ```vim
    Plug 'liuchengxu/vim-clap'
    Plug 'meck/vim-clap-hoogle'
    ```
- Launch with:
    ```vim
    :Clap hoogle
    ```
- Example bindings:
    ``` vim
    nnoremap <silent><Leader>h :Clap hoogle ++query=<cword><CR>
    nnoremap <silent><Leader>H :Clap hoogle<CR>
    ```
