function commit -d "Stage and generate AI commit message from diff"
    #
    set -l issue $argv[1]
    set -l diff (git diff --cached --stat | string collect)

    if test -z "$diff"
        set_color yellow
        echo "❌ No changes to commit."
        set_color normal
        return 0
    end

    set_color cyan
    echo $diff
    set_color normal

    echo ""
    echo "🤖 Generating commit message from staged changes..."
    echo ""

    set_color normal

    set -l prompt "Analyze this git diff and generate a concise, professional commit message following conventional commit format. Use the structure:
    <type>(<optional scope>): <short description><two newlines>

    <body and/or bullet points newline separated>

Example types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Include a body for more details in bullet points.
Just return the commit message as plain text. Do not wrap it in backticks or any other formatting."

    if command -q fm
        set msg (git diff --cached | fm respond --no-stream --instructions "$prompt" | string collect)
    else
        set msg (git diff --cached | claude -p --model sonnet "$prompt" | string collect)
    end

    if test -n "$issue"
        set msg (string join \n "$msg" "" "Fixes: $issue" | string collect)
    end

    echo
    set_color --bold
    echo " Generated commit message:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    set_color normal
    printf '%s\n' "$msg"
    echo ""
    set_color --bold
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    set_color normal
    read -P "Commit with this message? [y/N] " confirm

    if string match -qi y $confirm
        git commit -m "$msg"
        set_color green
        echo "=> Committed successfully."
        set_color normal
    else
        set_color red
        echo "=> Commit aborted. Changes remain staged."
        set_color normal
        clip "$msg"
    end
end
