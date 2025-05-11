# Default target when no arguments are provided
.PHONY: default
default:
	@echo "\033[33mWarning: Using make without a target is deprecated, please use \`\033[1mjust\033[0m\033[33m\` instead.\033[0m"
	@$(MAKE) --no-print-directory _install_and_run_just ARG=""

# Handle all other targets
.PHONY: %
%:
	@echo "\033[33mWarning: \`\033[1mmake $@\033[0m\033[33m\` is deprecated, please use \`\033[1mjust $@\033[0m\033[33m\` instead.\033[0m"
	@$(MAKE) --no-print-directory _install_and_run_just ARG="$@"

# Internal target to install just if needed and run it
.PHONY: _install_and_run_just
_install_and_run_just:
	@if command -v just >/dev/null 2>&1; then \
		just $(ARG); \
	else \
		echo "Just is not installed. Installing automatically..."; \
		if [ "$$(uname)" = "Darwin" ]; then \
			echo "Using Homebrew to install just..."; \
			if ! command -v brew >/dev/null 2>&1; then \
				echo "\033[31mError: Homebrew is not installed.\033[0m"; \
				echo "Please install Homebrew first: https://brew.sh/"; \
				exit 1; \
			fi; \
			brew install just; \
		else \
			if command -v pipx >/dev/null 2>&1; then \
				echo "Using pipx to install just..."; \
				pipx install rust-just; \
			else \
				echo "pipx not found, falling back to direct installation..."; \
				if [ -d "$$HOME/.local/bin" ] && echo "$$PATH" | grep -q "$$HOME/.local/bin"; then \
					destination="$$HOME/.local/bin"; \
				elif [ -w "/usr/local/bin" ]; then \
					destination="/usr/local/bin"; \
				else \
					destination="$$HOME/.local/bin"; \
					mkdir -p "$$destination"; \
					echo "Adding $$destination to PATH for this session"; \
					export PATH="$$destination:$$PATH"; \
				fi; \
				echo "Installing just to $$destination..."; \
				curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$$destination"; \
			fi; \
		fi; \
		if command -v just >/dev/null 2>&1; then \
			echo "Just installed successfully"; \
			just $(ARG); \
		else \
			echo "\033[31mError: Just installation failed.\033[0m"; \
			echo "Please install manually: https://github.com/casey/just#installation"; \
			exit 1; \
		fi; \
	fi
