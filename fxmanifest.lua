fx_version 'bodacious'
game 'gta5'
lua54 'yes'

author 'Mengazo'
description 'Mengazo Horizon - Marcadores do mapa projetados no horizonte'
version '1.0.0'

mengazo_production 'free'
mengazo_base 'standalone'

ui_page 'web/build/index.html'

client_scripts {
    'main/loader.lua',
    'main/title.lua',
    'main/points.lua',
    'main/client.lua'
}

server_scripts {
    'main/server.lua'
}

files {
    'config/config.lua',
    'web/build/index.html',
    'web/build/**/*'
}
