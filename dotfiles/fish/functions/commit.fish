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

Body: required unless the subject says everything (a typo, a version bump, a one-line fix). Separate it from the subject with a blank line and wrap at 72 columns. Write for a reviewer reading git log a year from now:
- what the change does in behavior terms: inputs, outputs, defaults, flags, thresholds, fallbacks, what a user now sees
- why, when the diff shows it: a code comment, an error message, a referenced radar or issue
- anything a reviewer could miss: a limitation, a migration, a breaking change

Use short prose paragraphs, or one \"- \" bullet per independent change when the commit makes several. Scale to the diff: 2-4 lines for a small change, a paragraph or bullet per part for a large one. Name concrete values (flag names, limits, endpoints) instead of words like \"improve\", \"update\" or \"support\".

Never:
- list the files, modules, functions, or classes added or changed
- mention tests, CLI/command registration, imports, or other wiring that follows from the main change
- restate the subject in the body
- invent a motivation the diff does not show

Output only the commit message as plain text, with no backticks or other formatting."

    set -l msg
    set -l pathspec ':/'
    for pattern in '*.lock' package-lock.json npm-shrinkwrap.json pnpm-lock.yaml go.sum '*.min.js' '*.min.css' '*.map'
        set -a pathspec ":(top,glob,exclude)**/$pattern"
    end

    # Apple's on-device fm model has a small context window; large diffs overflow
    # it and it emits nothing on stdout. Fall back to claude when fm is missing or fails.
    if command -q fm
        set msg (git diff --cached -- $pathspec | fm respond --model pcc --no-stream --instructions "$prompt" 2>/dev/null | string collect)
    end

    if test -z "$msg"
        set msg (git diff --cached -- $pathspec | claude -p --model sonnet "$prompt" | string collect)
    end

    if test -z "$msg"
        set_color red
        echo "❌ Failed to generate a commit message. Changes remain staged."
        set_color normal
        return 1
    end

    set -l wrapped
    for line in (string split \n -- $msg)
        set -l lead (string match -r '^\s*(?:[-*] |\d+\. )?' -- $line)
        set -l n (string length -- "$lead")
        set -l prefix "$lead"
        # fold -s breaks after the space, leaving trailing whitespace on each line.
        for part in (string sub -s (math $n + 1) -- $line | fold -s -w (math 72 - $n) | string trim --right)
            set -a wrapped "$prefix$part"
            set prefix (string repeat -n $n ' ')
        end
    end
    set msg (string join \n -- $wrapped | string collect)

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
