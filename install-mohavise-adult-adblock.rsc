# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# do-not-edit-manually

:do {
    :local scriptName "mohavise-adult-adblock-update"
    :local scheduleName "mohavise-adult-adblock-daily"
    :local adultUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt"
    :local marker "managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block component=adult"

    :local updateSource "
# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# do-not-edit-manually
:local adultUrl \"$adultUrl\"

:log info \"Mohavise adult adblock: starting DNS Adlist update\"

:do {
    :if ([:len [/ip dns adlist find url=\$adultUrl]] = 0) do={
        /ip dns adlist add url=\$adultUrl ssl-verify=no
        :log info \"Mohavise adult adblock: adult DNS Adlist URL added\"
    } else={
        :log info \"Mohavise adult adblock: adult DNS Adlist URL already exists; skipping add\"
    }
} on-error={
    :log error \"Mohavise adult adblock: failed to add or verify adult DNS Adlist URL\"
    :return
}

/ip dns adlist reload
:log info \"Mohavise adult adblock: DNS Adlist update completed\"
"

    :log info "Mohavise adult adblock: starting installer"

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName policy=read,write,test source=$updateSource comment=$marker
    } else={
        /system script set [/system script find name=$scriptName] source=$updateSource policy=read,write,test comment=$marker
    }

    :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
        /system scheduler add name=$scheduleName start-time=04:15:00 interval=1d on-event="/system script run mohavise-adult-adblock-update" comment=$marker
    } else={
        /system scheduler set [/system scheduler find name=$scheduleName] start-time=04:15:00 interval=1d on-event="/system script run mohavise-adult-adblock-update" comment=$marker
    }

    /system script run $scriptName

    :log info "Mohavise adult adblock: installer completed"
} on-error={
    :log error "Mohavise adult adblock: unexpected installer error"
}
