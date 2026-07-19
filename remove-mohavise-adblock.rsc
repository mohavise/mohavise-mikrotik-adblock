# managed-by=mohavise-mikrotik-adblock
# project=mohavise-adlist-block
# component=adblock
# action=remove
# do-not-edit-manually

:do {
    :local scriptName "mohavise-adblock-update"
    :local scheduleName "mohavise-adblock-daily"
    :local adblockUrl "https://raw.githubusercontent.com/mohavise/mohavise-mikrotik-adblock/main/mikrotik-adblock-hosts.txt"
    :local changed false

    :log info "Mohavise adblock: starting removal"

    :local scheduleIds [/system scheduler find name=$scheduleName]
    :if ([:len $scheduleIds] > 0) do={
        /system scheduler remove $scheduleIds
        :set changed true
        :log info "Mohavise adblock: scheduler removed"
    }

    :local scriptIds [/system script find name=$scriptName]
    :if ([:len $scriptIds] > 0) do={
        /system script remove $scriptIds
        :set changed true
        :log info "Mohavise adblock: updater script removed"
    }

    :local adlistIds [/ip dns adlist find url=$adblockUrl]
    :if ([:len $adlistIds] > 0) do={
        /ip dns adlist remove $adlistIds
        :set changed true
        :log info "Mohavise adblock: DNS Adlist entry removed"
    }

    :if ($changed = true) do={
        :do {
            /ip dns adlist reload
        } on-error={
            :log warning "Mohavise adblock: DNS Adlist reload failed after removal"
        }
    }

    :log info "Mohavise adblock: removal completed"
} on-error={
    :log error "Mohavise adblock: removal failed"
}
