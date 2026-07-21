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
    :local adlistId [/ip dns adlist find url=\$adultUrl]
    :if ([:len \$adlistId] = 0) do={
        /ip dns adlist add url=\$adultUrl ssl-verify=yes
        :log info \"Mohavise adult adblock: secure DNS Adlist URL added\"
    } else={
        /ip dns adlist set \$adlistId ssl-verify=yes
        :log info \"Mohavise adult adblock: existing DNS Adlist verification enabled\"
    }

    /ip dns adlist reload
} on-error={
    :log error \"Mohavise adult adblock: DNS Adlist update failed\"
    :return \"\"
}

:log info \"Mohavise adult adblock: DNS Adlist update completed\"
"

    :log info "Mohavise adult adblock: starting installer"

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName dont-require-permissions=no policy=read,write,test source=$updateSource comment=$marker
    } else={
        /system script set [/system script find name=$scriptName] dont-require-permissions=no source=$updateSource policy=read,write,test comment=$marker
    }

    :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
        /system scheduler add name=$scheduleName start-time=04:15:00 interval=1d on-event="/system script run mohavise-adult-adblock-update" policy=read,write,test comment=$marker
    } else={
        /system scheduler set [/system scheduler find name=$scheduleName] start-time=04:15:00 interval=1d on-event="/system script run mohavise-adult-adblock-update" policy=read,write,test comment=$marker
    }

    /system script run $scriptName

    :log info "Mohavise adult adblock: installer completed"
} on-error={
    :log error "Mohavise adult adblock: unexpected installer error"
}
