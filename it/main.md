# It
> Main and general notes

- [Github: dbohdan / automatic-api](https://github.com/dbohdan/automatic-api)
- api generator
    - Python-Eve
    - PostgREST
    - https://github.com/roapi/roapi
      - ROAPI automatically spins up read-only APIs for static datasets without requiring you to write a single line of code. It builds on top of Apache Arrow and Datafusion. The core of its design can be boiled down to the following:

- Fake API Data / Mock data:
    - https://randomuser.me/
    - https://www.mockaroo.com/

- airtable-like database:
    - https://www.cloudron.io/store/com.nocodb.cloudronapp.html
    - cloudron https://baserow.io/

- toggl time tracker alernative:
    - kimai https://www.cloudron.io/store/org.kimai.cloudronapp.html

random password in terminal
https://devdojo.com/alexg/bash-random-password-generator

- vimux repl postgresql
    - https://thegreata.pe/articles/2018/02/11/clojure-vim-and-tmux-using-your-editor-as-a-repl-scratchpad/
    - https://github.com/preservim/vimux

**wipe / erase / “format” disk or partition**

- pv --timer --rate --stop-at-size -s "$(blockdev --getsize64 /dev/sd"XY" )" /dev/zero > /dev/sd"XY"
- cp /dev/zero /dev/sd"XY"
- dd if=/dev/zero of=/dev/sdX bs=4096 status=progress

**note taking apps (privacy, open source)**
- standard notes https://standardnotes.com/?s=09

**systemd**

´systemctl edit myservice´
best practice to edit a service

**OBS Studio** record gravar video

ao add fonte capura de tela (web cam): ctrl+f centraliza a imagem da camera no enquadramento

1280x720: boa resolucao, economiza placa de video (evitar travar)
configurações: colocar os audios que quer que aparecam em todas as cenas
- desktop cpu + audio microfone

criar atalhos de teclado, em configurações, pra mudar de cena (numerico 1, 2 e 3?)
tb aalhos pra começar e interromper gracavao (<c-s-R>, <c-s-S)

