# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:local scriptName "mohavise-adblock-update"
:local scheduleName "mohavise-adblock-daily"
:local adlistUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/adblock-hosts.txt"

:local updateSource "
# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually
:local adlistUrl \"$adlistUrl\"
:if ([:len [/ip dns adlist find url=\$adlistUrl]] = 0) do={
    /ip dns adlist add url=\$adlistUrl ssl-verify=no
}
/ip dns adlist reload
"

:if ([:len [/system script find name=$scriptName]] = 0) do={
    /system script add name=$scriptName policy=read,write,test source=$updateSource
} else={
    /system script set [find name=$scriptName] source=$updateSource policy=read,write,test
}

:if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
    /system scheduler add name=$scheduleName start-time=04:10:00 interval=1d on-event="/system script run $scriptName" comment="managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block"
} else={
    /system scheduler set [find name=$scheduleName] start-time=04:10:00 interval=1d on-event="/system script run $scriptName" comment="managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block"
}

/system script run $scriptName
