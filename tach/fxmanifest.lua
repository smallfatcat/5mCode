fx_version "cerulean"
game 'gta5'

author 'SmallFatCat'
description 'Timer Test Functions'
version '1.0.0'

client_script 'client.lua'

server_scripts {
    "server.lua",
    "@mysql-async/lib/MySQL.lua"
    --[[ 
        the "@" references a file from a different resource,
        In this instance, we refernce the mysql library for FiveM.
    ]]
}
