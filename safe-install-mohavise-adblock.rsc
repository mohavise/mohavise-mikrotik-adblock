# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:do {
    :local installUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/install-mohavise-adblock.rsc"
    :local installFile "install-mohavise-adblock.rsc"

    /tool fetch url=$installUrl dst-path=$installFile mode=https
    /import file-name=$installFile
    /file remove [find name=$installFile]
}

