Srcds (init.d and systemd) services – choose the most suitable for you:
  /etc:       system-mode
  ~/.config:  user-mode (secure, but requires a clean user logon (not through "su"), or a user setup script, 
			see: https://unix.forumming.com/question/1880/starting-a-systemd-user-instance-for-a-user-from-a-shell )


Murse installation/updating tool: https://git.sr.ht/~welt/murse
  For Arch Linux users/servers: https://aur.archlinux.org/packages/murse-git

`./murse` just prints a usage help page.
Murse example command:
`steam@ip:~$ ./murse upgrade sdk2013/open_fortress/ -u https://toast-eu.openfortress.fun/toast/`
