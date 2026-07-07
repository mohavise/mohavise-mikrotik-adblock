# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:do {
    :local scriptName "mohavise-adblock-update"
    :local scheduleName "mohavise-adblock-daily"
    :local adlistUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/adblock-hosts.txt"
    :local marker "managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block"

    :local updateSource "
# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually
:local adlistUrl \"$adlistUrl\"

:log info \"Mohavise adblock: starting DNS Adlist update\"

:do {
    :if ([:len [/ip dns adlist find url=\$adlistUrl]] = 0) do={
        /ip dns adlist add url=\$adlistUrl ssl-verify=no
        :log info \"Mohavise adblock: DNS Adlist URL added\"
    } else={
        :log info \"Mohavise adblock: DNS Adlist URL already exists; skipping add\"
    }
} on-error={
    :log error \"Mohavise adblock: failed to add or verify DNS Adlist URL\"
    :return
}

:do {
    /ip dns adlist reload
} on-error={
    :log error \"Mohavise adblock: DNS Adlist reload failed\"
    :return
}

:log info \"Mohavise adblock: DNS Adlist update completed\"
"

    :log info "Mohavise adblock: starting installer"

    :do {
        :if ([:len [/system script find name=$scriptName]] = 0) do={
            /system script add name=$scriptName policy=read,write,test source=$updateSource comment=$marker
            :log info "Mohavise adblock: updater script created"
        } else={
            /system script set [/system script find name=$scriptName] source=$updateSource policy=read,write,test comment=$marker
            :log info "Mohavise adblock: updater script updated"
        }
    } on-error={
        :log error "Mohavise adblock: failed to create or update updater script"
        :return
    }

    :do {
        :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
            /system scheduler add name=$scheduleName start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" comment=$marker
            :log info "Mohavise adblock: daily scheduler created"
        } else={
            /system scheduler set [/system scheduler find name=$scheduleName] start-time=04:10:00 interval=1d on-event="/system script run mohavise-adblock-update" comment=$marker
            :log info "Mohavise adblock: daily scheduler updated"
        }
    } on-error={
        :log error "Mohavise adblock: failed to create or update daily scheduler"
        :return
    }

    :do {
        /system script run $scriptName
    } on-error={
        :log error "Mohavise adblock: first update run failed"
        :return
    }

    :log info "Mohavise adblock: installer completed"
} on-error={
    :log error "Mohavise adblock: unexpected installer error"
}
