# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:local scriptName "mohavise-adblock-update"
:local scheduleName "mohavise-adblock-daily"
:local remoteUrl "https://raw.githubusercontent.com/YOUR-USER/YOUR-REPO/main/adblock-prototype/adblock-domains.rsc"
:local localFile "mohavise-adblock-domains.rsc"

/system script remove [/system script find name=$scriptName]
/system script add name=$scriptName policy=read,write,test source="
# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually
:local remoteUrl \"$remoteUrl\"
:local localFile \"$localFile\"
/tool fetch url=\$remoteUrl dst-path=\$localFile mode=https
/import file-name=\$localFile
"

/system scheduler remove [/system scheduler find name=$scheduleName]
/system scheduler add name=$scheduleName start-time=04:10:00 interval=1d on-event="/system script run $scriptName" comment="managed-by=mohavise-mikrotik-adblock project=mohavise-adlist-block"

/system script run $scriptName

