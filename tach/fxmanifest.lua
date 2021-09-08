fx_version "cerulean"
game 'gta5'

author 'SmallFatCat'
description 'Timer Test Functions'
version '1.0.0'

client_scripts {
    'c_main.lua',
    'c_commands.lua',
    'c_handlers.lua',
    'c_threads.lua',
    'c_sw.lua'
}

server_scripts {
    "s_main.lua",
    "@mysql-async/lib/MySQL.lua"
}
