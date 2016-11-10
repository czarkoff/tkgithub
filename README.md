TkGitHub periodically retrievs GitHub notifications and displays them in a drop
menu attached to its system tray icon. Clicking on notification opens
corresponding page on GitHub; notification is marked as read.

The icon indicates whether there are unread notifications. If unread
notifications are available a popup menu will contain a *Mark all read* command
and commands for individual discussion threads. The popup menu always contains
an *Exit* command, which is the preferred way of exiting application.

Balloon tooltip for system tray icon shows the time of the last connection to
GitHub. Depending on system tray implementation, balloon tooltips may not be
shown.

TkGitHub needs a valid GitHub personal access token for its operation, and it is
user's responsibility to provide one. The token may be acquired from GutHub
settings page “[Personal access tokens](https://github.com/settings/tokens)”.

TkGitHub may be used either from the repo directory directly (in which case it
could be launched with `./tkgithub.tcl` or `wish tkgithub.tcl`), or may be
installed.  Provided Makefile would respect the variables `PREFIX`, `BINDIR`,
`MANDIR`, `DATADIR` and `DESKTOPDIR`, which correspond to desired installation
prefix, binary, manuals, application data and XDG .desktop files directories
respectively.  Additional variable `WISH` may be set to `wish` binary location.
