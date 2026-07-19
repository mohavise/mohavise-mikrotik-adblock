# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# do-not-edit-manually

:do {
    :local installUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/install-mohavise-adult-adblock.rsc"
    :local installFile "install-mohavise-adult-adblock.rsc"

    :log info "Mohavise adult adblock: starting safe installer"

    :if ([:len [/file find name=$installFile]] > 0) do={
        /file remove [find name=$installFile]
    }

    :do {
        /tool fetch url=$installUrl dst-path=$installFile check-certificate=yes-without-crl
    } on-error={
        :log error "Mohavise adult adblock: failed secure installer download"
        :return
    }

    :do {
        /import file-name=$installFile verbose=yes dry-run
    } on-error={
        :log error "Mohavise adult adblock: installer syntax validation failed"
        /file remove [find name=$installFile]
        :return
    }

    :do {
        /import file-name=$installFile
    } on-error={
        :log error "Mohavise adult adblock: failed to import installer"
        /file remove [find name=$installFile]
        :return
    }

    /file remove [find name=$installFile]
    :log info "Mohavise adult adblock: safe installer completed"
} on-error={
    :log error "Mohavise adult adblock: unexpected safe installer error"
}
