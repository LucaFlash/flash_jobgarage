fx_version 'cerulean'
game 'gta5'

author 'LucaFlash'
description 'Garage Job using ox_target and ox_lib'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'config.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}