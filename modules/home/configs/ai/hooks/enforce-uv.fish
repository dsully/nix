#!/usr/bin/env fish

# Hook to enforce using uv

# Handle pip install command
function handle_pip_install
    set -l pip_cmd $argv[1]
    set -l packages (echo "$pip_cmd" | sed 's/install//' | sed 's/--[^ ]*//g' | string trim)

    # -r requirements.txt
    if string match -qr -- '-r .*\.txt' "$pip_cmd"
        set -l req_file (echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
        echo '{
  "decision": "block",
  "reason": "📋 Installing from requirements.txt:

✅ Recommended method:
uv add -r '$req_file'

This will:
• Add all dependencies from requirements.txt to pyproject.toml
• Automatically generate/update uv.lock file
• Automatically sync the virtual environment

💡 If you have a constraints file:
uv add -r '$req_file' -c constraints.txt

📌 Note: This method is the most reliable and handles version specifications correctly"
}'
        exit 0
    end

    # Development dependencies
    if string match -qr -- --dev "$pip_cmd"; or string match -qr -- -e "$pip_cmd"
        echo '{
  "decision": "block",
  "reason": "🔧 Installing development dependencies:

uv add --dev '$packages'

Editable install: uv add -e ."
}'
        exit 0
    end

    # Normal install
    echo '{
  "decision": "block",
  "reason": "📦 Installing packages:

uv add '$packages'

💾 '\''uv add'\'' saves dependencies to pyproject.toml
🔒 uv.lock ensures reproducible environments

💡 Special cases:
• Installing from URL: Manually download the package then add
• Development version: uv add --dev '$packages'
• Local package: uv add -e ./path/to/package"
}'
    exit 0
end

# Handle pip uninstall command
function handle_pip_uninstall
    set -l pip_cmd $argv[1]
    set -l packages (echo "$pip_cmd" | sed 's/uninstall//' | sed 's/-y//g' | string trim)
    echo '{
  "decision": "block",
  "reason": "🗑️ Removing packages:

uv remove '$packages'

✨ Dependencies are automatically cleaned up"
}'
    exit 0
end

# Handle pip list/freeze command
function handle_pip_list
    echo '{
  "decision": "block",
  "reason": "📊 Checking package list:

• Project dependencies: cat pyproject.toml
• Lock file details: cat uv.lock
• Installed packages: uv tree
• Export as requirements.txt format: uv export --format requirements-txt

💡 '\''uv tree'\'' displays the project dependency tree"
}'
    exit 0
end

# Handle other pip commands
function handle_pip_other
    set -l pip_cmd $argv[1]
    echo '{
  "decision": "block",
  "reason": "🔀 Running pip command with uv:

uv '$pip_cmd'

💡 Use '\''uv add/remove'\'' for installing/removing packages"
}'
    exit 0
end

# Handle python -m pip command
function handle_python_m_pip
    set -l pip_cmd $argv[1]

    # Parse pip install commands
    if string match -qr '^install' "$pip_cmd"
        set -l packages (echo "$pip_cmd" | sed 's/install//' | sed 's/--[^ ]*//g' | string trim)
        if string match -qr -- '-r .*\.txt' "$pip_cmd"
            set -l req_file (echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
            echo '{
  "decision": "block",
  "reason": "📋 Installing from requirements.txt:

✅ Recommended method:
uv add -r '$req_file'

💡 This will add all dependencies to pyproject.toml"
}'
        else
            echo '{
  "decision": "block",
  "reason": "📦 Installing packages:

uv add '$packages'

💡 '\''uv add'\'' saves dependencies to pyproject.toml"
}'
        end
    else
        echo '{
  "decision": "block",
  "reason": "🔀 Running pip command with uv:

uv '$pip_cmd'

💡 Use '\''uv add/remove'\'' for package management"
}'
    end
    exit 0
end

# Handle python -m module command
function handle_python_m_module
    set -l module $argv[1]
    echo '{
  "decision": "block",
  "reason": "Running module with uv:

uv run python -m '$module'

🔄 uv automatically syncs the environment before execution."
}'
    exit 0
end

# Handle basic Python execution
function handle_python_run
    set -l args $argv[1]
    echo '{
  "decision": "block",
  "reason": "Running Python with uv:

uv run '$args'

✅ No need to activate the virtual environment!"
}'
    exit 0
end

# ===== Main Processing =====
function main
    set -l input (cat)

    # Validate input
    if test -z "$input"
        echo '{"decision": "approve"}'
        exit 0
    end

    # Extract fields with error handling
    set -l tool_name (echo "$input" | jq -r '.tool_name' 2>/dev/null; or echo "")
    set -l command (echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null; or echo "")
    # set -l file_path (echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null; or echo "")
    # set -l current_dir (pwd)

    # ===== pip-related commands =====
    if test "$tool_name" = Bash
        # Detect pip commands
        if string match -qr '^pip[0-9]? ' "$command"; or string match -qr '^pip3 ' "$command"
            # Detailed parsing of pip commands
            set -l pip_cmd (echo "$command" | sed -E 's/^pip[0-9]? *//' | string trim)

            if string match -qr '^install ' "$pip_cmd"
                handle_pip_install "$pip_cmd"
            else if string match -qr '^uninstall ' "$pip_cmd"
                handle_pip_uninstall "$pip_cmd"
            else if string match -qr '^list' "$pip_cmd"; or string match -qr '^freeze' "$pip_cmd"
                handle_pip_list
            else
                handle_pip_other "$pip_cmd"
            end
        end

        # ===== Handle direct Python execution =====
        if string match -qr '^python[0-9]* ' "$command"; or string match -qr '^py ' "$command"
            # Normal conversion to uv
            set -l args (echo "$command" | sed -E 's/^python[0-9]* //' | string trim)

            # Special handling for -m option
            if string match -qr '^-m ' "$args"
                set -l module (echo "$args" | sed 's/-m //')

                if string match -qr '^pip ' "$module"
                    set -l pip_cmd (echo "$module" | sed 's/pip //')
                    handle_python_m_pip "$pip_cmd"
                else
                    handle_python_m_module "$module"
                end
            end

            # Basic Python execution
            handle_python_run "$args"
        end
    end

    # Default is approve
    echo '{"decision": "approve"}'
end

# Execute script
main
