# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# do-not-edit-manually

:do {
    :local installUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/install-mohavise-adblock.rsc"
    :local installFile "install-mohavise-adblock.rsc"

    :log info "Mohavise adblock: starting safe installer"

    :if ([:len [/file find name=$installFile]] > 0) do={
        :do {
            /file remove [find name=$installFile]
        } on-error={
            :log warning "Mohavise adblock: could not remove old installer file before download"
        }
    }

    :do {
        /tool fetch url=$installUrl dst-path=$installFile mode=https
    } on-error={
        :log error "Mohavise adblock: failed to download installer"
        :return
    }

    :if ([:len [/file find name=$installFile]] = 0) do={
        :log error "Mohavise adblock: installer file was not created after download"
        :return
    }

    :do {
        /import file-name=$installFile
    } on-error={
        :log error "Mohavise adblock: failed to import installer"
        :do {
            /file remove [find name=$installFile]
        } on-error={
            :log warning "Mohavise adblock: could not remove installer file after failed import"
        }
        :return
    }

    :do {
        /file remove [find name=$installFile]
    } on-error={
        :log warning "Mohavise adblock: installer imported but temporary file could not be removed"
    }

    :log info "Mohavise adblock: safe installer completed"
} on-error={
    :log error "Mohavise adblock: unexpected safe installer error"
}
