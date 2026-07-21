# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:do {
    :local installUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/install-mohavise-adblock.rsc"
    :local installFile "install-mohavise-adblock.rsc"

    :log info "Mohavise adblock: starting safe installer"

    :if ([:len [/file find name=$installFile]] > 0) do={
        /file remove [find name=$installFile]
    }

    :do {
        /tool fetch url=$installUrl dst-path=$installFile check-certificate=yes-without-crl
    } on-error={
        :log error "Mohavise adblock: failed secure installer download"
        :return ""
    }

    :do {
        /import file-name=$installFile verbose=yes dry-run
    } on-error={
        :log error "Mohavise adblock: installer syntax validation failed"
        /file remove [find name=$installFile]
        :return ""
    }

    :do {
        /import file-name=$installFile
    } on-error={
        :log error "Mohavise adblock: failed to import installer"
        /file remove [find name=$installFile]
        :return ""
    }

    /file remove [find name=$installFile]
    :log info "Mohavise adblock: safe installer completed"
} on-error={
    :log error "Mohavise adblock: unexpected safe installer error"
}
