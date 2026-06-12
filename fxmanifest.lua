fx_version 'cerulean'
game 'gta5'

name 'rc_me'
description 'Roleplay /me for ESX & QBCore — concurrent, stackable 3D text bubbles with Discord name/avatar and server-side proximity'
author 'sudo-umair'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'bridge/server.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib'
}
