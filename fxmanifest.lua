fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rex-farming'
version '2.1.2'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/client.lua',
    'client/modules/placeprop.lua',
    'client/modules/collectwater.lua',
    'client/modules/collectfertilizer.lua',
    'client/modules/vegmod.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'PolyZone'
}

files {
    'locales/*.json',
    'stream/prop_weed_ytyp.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/prop_weed_ytyp.ytyp'

this_is_a_map 'yes'

lua54 'yes'
