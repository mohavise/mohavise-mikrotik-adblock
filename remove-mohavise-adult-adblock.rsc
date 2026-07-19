# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adult
# action=remove
# do-not-edit-manually

:do {
    :local scriptName "mohavise-adult-adblock-update"
    :local scheduleName "mohavise-adult-adblock-daily"
    :local adultUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adult-hosts.txt"
    :local changed false

    :log info "Mohavise adult adblock: starting removal"

    :local scheduleIds [/system scheduler find name=$scheduleName]
    :if ([:len $scheduleIds] > 0) do={
        /system scheduler remove $scheduleIds
        :set changed true
        :log info "Mohavise adult adblock: scheduler removed"
    }

    :local scriptIds [/system script find name=$scriptName]
    :if ([:len $scriptIds] > 0) do={
        /system script remove $scriptIds
        :set changed true
        :log info "Mohavise adult adblock: updater script removed"
    }

    :local adlistIds [/ip dns adlist find url=$adultUrl]
    :if ([:len $adlistIds] > 0) do={
        /ip dns adlist remove $adlistIds
        :set changed true
        :log info "Mohavise adult adblock: DNS Adlist entry removed"
    }

    :if ($changed = true) do={
        :do {
            /ip dns adlist reload
        } on-error={
            :log warning "Mohavise adult adblock: DNS Adlist reload failed after removal"
        }
    }

    :log info "Mohavise adult adblock: removal completed"
} on-error={
    :log error "Mohavise adult adblock: removal failed"
}
