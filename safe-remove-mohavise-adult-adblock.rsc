# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# action=safe-remove
# do-not-edit-manually

:do {
    :local removeUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/remove-mohavise-adult-adblock.rsc"
    :local removeFile "remove-mohavise-adult-adblock.rsc"

    :log info "Mohavise adult adblock: starting safe removal"

    :if ([:len [/file find name=$removeFile]] > 0) do={
        /file remove [find name=$removeFile]
    }

    :do {
        /tool fetch url=$removeUrl dst-path=$removeFile check-certificate=yes-without-crl
    } on-error={
        :log error "Mohavise adult adblock: failed secure remover download"
        :return ""
    }

    :do {
        /import file-name=$removeFile verbose=yes dry-run
    } on-error={
        :log error "Mohavise adult adblock: remover syntax validation failed"
        /file remove [find name=$removeFile]
        :return ""
    }

    :do {
        /import file-name=$removeFile
    } on-error={
        :log error "Mohavise adult adblock: failed to import remover"
        /file remove [find name=$removeFile]
        :return ""
    }

    /file remove [find name=$removeFile]
    :log info "Mohavise adult adblock: safe removal completed"
} on-error={
    :log error "Mohavise adult adblock: unexpected safe removal error"
}
