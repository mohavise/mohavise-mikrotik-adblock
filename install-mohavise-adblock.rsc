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
    :if ([:len [/ip dns adlist find url=\$adblockUrl]] = 0) do={
        /ip dns adlist add url=\$adblockUrl ssl-verify=no
        :log info \"Mohavise adblock: adblock DNS Adlist URL added\"
    } else={
        :log info \"Mohavise adblock: adblock DNS Adlist URL already exists; skipping add\"
    }
} on-error={
    :log error \"Mohavise adblock: failed to add or verify adblock DNS Adlist URL\"
    :return
}

/ip dns adlist reload
:log info \"Mohavise adblock: DNS Adlist update completed\"
"

    :log info "Mohavise adblock: starting installer"

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName policy=read,write,test source=$updateSource comment=$marker
    } else={
        /system script set [/system script find name=$scriptName] source=$updateSource policy=read,write,test comment=$marker
    }

    :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
        /system scheduler add name=$scheduleName start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" comment=$marker
    } else={
        /system scheduler set [/system scheduler find name=$scheduleName] start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" comment=$marker
    }

    /system script run $scriptName

    :log info "Mohavise adblock: installer completed"
} on-error={
    :log error "Mohavise adblock: unexpected installer error"
}
