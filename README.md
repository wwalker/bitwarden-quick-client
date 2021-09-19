# bitwarden-quick-client
bitwarden-quick-client

NOTE: I recommend looking into these projects instead.  They are both more polished than this project by far.

github.com:mattydebie/bitwarden-rofi
git@github.com:fdw/rofi-rbw

The rest of this is just left here for legacy info.

For me, the [Bitwarden Desktop Application]( https://github.com/bitwarden/desktop ) is terribly slow ( 50 second startup time on a Xeon E3-1285L v4 @ 3.40GHz )and is huge from a screen real estate viewpoint.  The firefox browser integration almost never succeeds to autofill.  It also fails to icon to the panel for me.

Therefore, I have created a script that provides relatively fast ( 1 to 3 seconds ) access to data for a given site.  Currently, this script (and the functions it provides) are for bash ( only tested with v5.0.0+ ) only, and copy the result into the clipboard.  It is also dependent upon [`rofi`](https://github.com/davatorium/rofi), though `fzf`, `dmenu`, etc. could be plugged in rather easily.

## Usage:

`bitwarden-quick-client password <optional filter>`
`bitwarden-quick-client username <optional filter>`
`bitwarden-quick-client url <optional filter>`
`bitwarden-quick-client bw_edit <uuid>`
`bitwarden-quick-client bw_create <item name> <item url> <item username>`

### Set up your window manager to simplify usage:
For i3:
```
bindsym --release $mod+u exec --no-startup-id bitwarden-quick-client user
bindsym --release $mod+p exec --no-startup-id bitwarden-quick-client pass
```

### BUGS:
* only outputs to the clipboard (and to the primary) X buffers, no text output.
* doesn't automatically delete the password from the buffers

### Planned features:
* support for alternates to `rofi`; e.g., `fzf`, `dmenu`
* automatically delete the password from the buffers as soon as it is used (or a short configurable time period)
* "type" ( `xdotool` ) the data rather than put it in unsecure clipboard buffers.
* support different terminals ( currently uses `xterm` ) for `bw` master password entry
  * `bw` doesn't support external password entry programs
  * other password managers do
    * e.g., `lpass` requires a `gpg` `pinentry` program ( terminal or X based )
  * or get `bw` to support `pinentry` programs
