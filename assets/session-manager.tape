Output assets/session-manager.gif

Require bash
Require fzf

Set Shell "bash"
Set FontSize 36
Set Width 1200
Set Height 650
Set Theme "OneHalfDark"
Set TypingSpeed 30ms
Set Margin 32
Set MarginFill "#0b0c10"
Set WindowBar "Colorful"

Hide
Type "cd /home/tkcd/ex_prog/ex_tmux/tmux-session-manager"
Enter
Type "export PATH=/home/tkcd/ex_prog/ex_tmux/tmux-session-manager/assets/mock/bin:$PATH"
Enter
Type "clear"
Enter
Show

Type "printf '\n tmux-session-manager demo\n\n'"
Enter
Sleep 500ms

Type "echo 'Session overview (session-mode)'"
Enter
Type "bash scripts/session-mode.sh"
Enter
Sleep 1200ms
Down
Sleep 700ms
Down
Sleep 700ms
Up
Sleep 700ms
Type "q"
Sleep 900ms

Type "printf '\n'"
Enter
Type "echo 'Window drill-down (detail-mode)'"
Enter
Type "bash scripts/detail-mode.sh alpha"
Enter
Sleep 900ms
Down
Sleep 700ms
Up
Sleep 700ms
Escape
Sleep 900ms

Type "printf '\n'"
Enter
Type "echo 'Pane inspection (pane-mode)'"
Enter
Type "bash scripts/pane-mode.sh alpha 0"
Enter
Sleep 900ms
Down
Sleep 700ms
Up
Sleep 700ms
Escape
Sleep 900ms

Type "printf '\nAll done!\n'"
Enter
Sleep 1200ms
