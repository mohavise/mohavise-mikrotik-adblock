# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adblock
# do-not-edit-manually

:do {
    :local scriptName "mohavise-adblock-update"
    :local scheduleName "mohavise-adblock-daily"
    :local adblockUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt"
    :local marker "managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block component=adblock"

    :local updateSource "
# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adblock
# do-not-edit-manually
:local adblockUrl \"$adblockUrl\"

:log info \"Mohavise adblock: starting DNS Adlist update\"

:do {
    :local adlistId [/ip dns adlist find url=\$adblockUrl]
    :if ([:len \$adlistId] = 0) do={
        /ip dns adlist add url=\$adblockUrl ssl-verify=yes
        :log info \"Mohavise adblock: secure DNS Adlist URL added\"
    } else={
        /ip dns adlist set \$adlistId ssl-verify=yes
        :log info \"Mohavise adblock: existing DNS Adlist verification enabled\"
    }

    /ip dns adlist reload
} on-error={
    :log error \"Mohavise adblock: DNS Adlist update failed\"
    :return \"\"
}

:log info \"Mohavise adblock: DNS Adlist update completed\"
"

    :log info "Mohavise adblock: starting installer"

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName dont-require-permissions=no policy=read,write,test source=$updateSource comment=$marker
    } else={
        /system script set [/system script find name=$scriptName] dont-require-permissions=no source=$updateSource policy=read,write,test comment=$marker
    }

    :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
        /system scheduler add name=$scheduleName start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" policy=read,write,test comment=$marker
    } else={
        /system scheduler set [/system scheduler find name=$scheduleName] start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" policy=read,write,test comment=$marker
    }

    /system script run $scriptName

    :log info "Mohavise adblock: installer completed"
} on-error={
    :log error "Mohavise adblock: unexpected installer error"
}
