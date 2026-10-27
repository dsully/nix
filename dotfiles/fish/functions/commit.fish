function commit -d "Stage and generate AI commit message from diff"
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

    set -l prompt "Write a git commit message for the staged diff, in conventional commit format.

Subject line: <type>(<scope>): <summary>
- type: one of feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- scope: optional, one word naming the area affected
- summary: imperative mood, lowercase, under 60 characters. Say what the change does, not which files it touches.

Body: optional. Most commits need none. Add one only for something a reviewer cannot get from the subject: a non-obvious behavior, a limitation, or a breaking change. Keep it to 1-3 short lines.

Never:
- list the files, modules, functions, or classes added or changed
- mention tests, CLI/command registration, imports, or other wiring that follows from the main change
- restate the subject in the body
- invent a motivation the diff does not show

Output only the commit message as plain text, with no backticks or other formatting."

    set -l msg

    # Apple's on-device fm model has a small context window; large diffs overflow
    # it and it emits nothing on stdout. Fall back to claude when fm is missing or fails.
    if command -q fm
        set msg (git diff --cached | fm respond --model pcc --no-stream --instructions "$prompt" 2>/dev/null | string collect)
    end

    if test -z "$msg"
        set msg (git diff --cached | claude -p --model sonnet "$prompt" | string collect)
    end

    if test -z "$msg"
        set_color red
        echo "❌ Failed to generate a commit message. Changes remain staged."
        set_color normal
        return 1
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
        printf '%s' "$msg" | fish_clipboard_copy
    end
end
