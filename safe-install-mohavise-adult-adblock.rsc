# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# do-not-edit-manually

:do {
    :local installUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/install-mohavise-adult-adblock.rsc"
    :local installFile "install-mohavise-adult-adblock.rsc"

    :log info "Mohavise adult adblock: starting safe installer"

    :if ([:len [/file find name=$installFile]] > 0) do={
        :do {
            /file remove [find name=$installFile]
        } on-error={
            :log warning "Mohavise adult adblock: could not remove old installer file before download"
        }
    }

    :do {
        /tool fetch url=$installUrl dst-path=$installFile mode=https
    } on-error={
        :log error "Mohavise adult adblock: failed to download installer"
        :return
    }

    :do {
        /import file-name=$installFile
    } on-error={
        :log error "Mohavise adult adblock: failed to import installer"
        :return
    }

    :do {
        /file remove [find name=$installFile]
    } on-error={
        :log warning "Mohavise adult adblock: installer imported but temporary file could not be removed"
    }

    :log info "Mohavise adult adblock: safe installer completed"
} on-error={
    :log error "Mohavise adult adblock: unexpected safe installer error"
}
