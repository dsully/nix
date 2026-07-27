# zmx - terminal session persistence. https://zmx.sh
#
# On an interactive shell that is not already inside a session, present the
# fuzzy picker to attach/create. Detaching or exiting the session exits the
# shell (so closing a Ghostty tab is a clean detach); cancelling the picker
# with Ctrl-C drops into a normal shell as an escape hatch.
if status is-interactive; and command -q zmx; and command -q fzf; and not set -q ZMX_SESSION
    zmx-select; and exit
end
