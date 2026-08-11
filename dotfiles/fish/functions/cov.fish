function cov --wraps=pytest
    set -l cov_args --cov src

    if test -f pyproject.toml
        set -l modules (yq -p toml -oy '.tool.uv.build-backend.module-name | select(. != null) | .[]? // .' pyproject.toml 2>/dev/null)

        if test (count $modules) -gt 0
            set cov_args
            for module in $modules
                set -a cov_args --cov $module
            end
        end
    end

    command pytest --cov-report html $cov_args $argv

    if test -f htmlcov/index.html
        command /usr/bin/open --background htmlcov/index.html
    end
end
