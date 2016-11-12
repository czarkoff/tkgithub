#!/usr/bin/env wish

package require http
package require json
package require tls
package require tktray

wm withdraw .

set version 0.1

tk appname TkGitHub

set datadir "DATADIR"

if {[info exists env{XDG_CONFIG_DIR}]} {
    set configroot "${env(XDG_CONFIG_DIR)}"
} else {
    set configroot "${env(HOME)}/.config"
}
# Read configuration
if {![file exists $configroot]} {
    puts "Can't access $configroot directory"
    exit 1
}

set rc $configroot/tkgithubrc

set balloon_timeout 10000
set check_timeout 1
set browser "xdg-open"
catch {set gh_token $env(GH_TOKEN)}
set filename_unread "$datadir/unread.png"
set filename_read "$datadir/read.png"
set cert "/etc/ssl/cert.pem"

catch {source $rc}

if {![info exists gh_token]} {
    set e "No GitHub token provided"
    set d "See [tk appname] manual for details."
    tk_messageBox -type ok -icon error -detail $d -message $e -title $e
    exit 1
}

# Set headers
set base_headers [dict create Authorization "token $gh_token" \
                                Accept "application/vnd.github.v3.full+json"]
set headers $base_headers

http::config -useragent "TkGitHub $version"
http::register https 443 [list ::tls::socket -require 1 -cafile $cert]

set notifications {}

image create photo icon
image create photo icon_read
image create photo icon_unread
tktray::icon .t -class TkgithubIcon -visible 1 -image icon

proc max {p q} {
    if {$p > $q} {return $p}
    return $q
}

proc lcm {p q} {
    set m [expr $p * $q]
    if {$m == 0} {return 0}
    while 1 {
        set p [expr $p % $q]
        if {$p == 0} {return [expr $m / $q]}
        set q [expr $q % $p]
        if {$q == 0} {return [expr $m / $p]}
    }
}

set p [menu .p -tearoff 0]

proc initicons {} {
    global datadir
    global icon icon_read icon_unread

    set coords [.t bbox]
    set dsize [expr [lindex $coords 2] - [lindex $coords 0]]
    if {$dsize <= 1} return

    image create photo icon_t
    foreach t {"unread" "read"} {
        icon_$t read "$datadir/$t.png"

        set ssize [image width icon_$t]
        set mul [lcm $dsize $ssize]
        set zoomf [expr $mul / $ssize]
        set ssf [expr $mul / $dsize]

        icon_t copy icon_$t -shrink -zoom $zoomf
        icon_$t copy icon_t -shrink -subsample $ssf
    }

    image delete icon_t
}

bind .t <ButtonPress-3> {
    mkmenu
    tk_popup .p %X %Y
}

bind .t <ButtonPress-1> {
    mkmenu
    tk_popup .p %X %Y
}

proc go {id} {
    global notifications
    global browser

    set url [dict get [dict get $notifications $id] url]

    exec -ignorestderr $browser $url &
    set notifications [dict remove $notifications $id]
    mkmenu
}

proc mkmenu {} {
    global p
    global notifications

    set repos [dict create]
    set names [list]

    $p delete 0 end
    if {[dict size $notifications] > 0} {
        dict for {id d} $notifications {
            set repo [dict get $d repo]
            if {![dict exists $repos $repo]} {
                dict lappend repos $repo $id
                lappend names $repo
            } else {
                dict lappend repos $repo $id
            }
        }

        $p add command -label "Mark all read" -command markallread
        foreach repo $names {
            $p add separator
            $p add command -label $repo -state disabled
            foreach id [dict get $repos $repo] {
                set title [dict get [dict get $notifications $id] title]
                $p add command -label $title -command [list go $id]
            }
        }
        $p add separator
    } else {
        $p add command -label "No unread notifications" -state disabled
    }
    $p add command -label "Exit" -command [list exit 0]
}

proc getinfo {} {
    global base_headers headers

    set url https://api.github.com/notifications
    http::geturl $url -headers $headers -command parseinfo
}

proc parseinfo {tok} {
    global base_headers headers
    global notifications
    global check_timeout
    global balloon_timeout
    global icon icon_read icon_unread

    set h [http::meta $tok]
    set d [http::data $tok]
    http::cleanup $tok

    set ts [dict get $h Date]

    if {[string length $d] > 0} {
        foreach event [json::json2dict $d] {
            set id [dict get $event id]
            set title [dict get [dict get $event subject] title]
            set type [dict get [dict get $event subject] type]
            set repo [dict get [dict get $event repository] full_name]

            # Extract HTML url
            set t_url [dict get [dict get $event subject] latest_comment_url]
            set tok [http::geturl $t_url -headers $base_headers]
            set url [dict get [json::json2dict [http::data $tok]] html_url]
            http::cleanup $tok

            set d [dict create]
            dict append d repo $repo
            dict append d title "$title ($type)"
            dict append d url $url

            dict set notifications $id $d
        }
    }
    .t balloon [clock format [clock scan $ts]] $balloon_timeout

    dict set headers If-Modified-Since $ts
    set timeout [max $check_timeout [expr [dict get $h X-Poll-Interval] * 1000]]
    after $timeout getinfo

    if {[image width icon] == 0} initicons
    if {[dict size $notifications] > 0} {
        icon copy icon_unread
    } else {
        icon copy icon_read
    }
}

proc markallread {} {
    global notifications
    global headers

    set url https://api.github.com/notifications
    set date [dict get $headers If-Modified-Since]
    set query "{\"last_read_at\": \"$date\"}"
    http::geturl $url -command http::cleanup -query $query -method PUT -headers $headers

    set notifications {}
}

getinfo
