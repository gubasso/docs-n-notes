# Spell

## General

Spellcheck / spell:

```vimscript
:spellr
```

- repeats the last spelling correction for all matches that was corrected

## Download / Generate Dictionary / Language

A melhor abordagem é baixar os dicionários corretos e garantir que estejam no local esperado pelo Neovim.

### Baixar arquivos compatíveis 

Use os dicionários do **Hunspell** , que são os mesmos usados pelo LibreOffice:

```bash
mkdir -p ~/.local/share/nvim/site/spell
cd ~/.local/share/nvim/site/spell
wget -O pt_BR.aff https://cgit.freedesktop.org/libreoffice/dictionaries/plain/pt_BR/pt_BR.aff
wget -O pt_BR.dic https://cgit.freedesktop.org/libreoffice/dictionaries/plain/pt_BR/pt_BR.dic
```

Agora, gere o arquivo `.spl` para o Neovim reconhecer o dicionário:

```bash
nvim -c 'set spelllang=pt_br | mkspell! pt_br' -c 'q'
```

### 2️⃣ Configurar no Neovim 

Edite seu `init.vim` ou `init.lua`: 

- **Para `init.vim`** :

```vim
set spell
set spelllang=pt_br
```
 
- **Para `init.lua`** :

```lua
vim.opt.spell = true
vim.opt.spelllang = { 'pt_br' }
```

### 3️⃣ Teste no Neovim 

Abra qualquer arquivo de texto e veja se a verificação ortográfica está funcionando:


```vim
:echo &spelllang
```
Se a saída for `pt_br`, está tudo certo! 🚀
Caso continue com erro, me avise que podemos tentar outra abordagem!
