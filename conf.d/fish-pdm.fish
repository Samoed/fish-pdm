if command -s pdm > /dev/null

    # function that loads environment variables from a file
    function posix-source
        set -l loaded_vars # Local variable to hold the names of loaded variables
        for i in (cat $argv)
            if test (echo $i | sed -E 's/^[[:space:]]*(.).+$/\\1/g') != "#" && test -n $i
                set arr (string split -m1 = $i)
                set -gx $arr[1] $arr[2]
                set loaded_vars $loaded_vars $arr[1] # Remember the variable name
            end
        end
        set -Ux __pdm_loaded_vars $loaded_vars # Store the names in a universal variable for later use
    end

    function __pdm_shell_activate --on-variable PWD
        if status --is-command-substitution
            return
        end

        # Deactivation check: if moving out of a project directory, deactivate the environment
        if not test -e "$PWD/pyproject.toml"
            if set -q __pdm_fish_initial_pwd
                # echo "Deactivating PDM environment..."
                # Check if 'deactivate' command exists and call it if so
                # beacuse of conflict with fish-poetry/fish-pipenv
                if type -q deactivate
                    deactivate
                    echo "PDM environment deactivated."
                end

                set -e __pdm_fish_initial_pwd

                # Clear the list of loaded variable names
                for var_name in $__pdm_loaded_vars
                    set -e $var_name
                end
                set -e __pdm_loaded_vars

            end
            return
        end

        # Activation
        if test -e "$PWD/pyproject.toml"
            if not set -q __pdm_fish_initial_pwd
                echo "Activating PDM environment..."
                set -gx __pdm_fish_initial_pwd "$PWD"
                eval (pdm venv activate)

                if test "$FISH_PDM_LOAD_ENV" -a -e "$PWD/.env"
                    echo "Setting environment variables..."
                    posix-source $PWD/.env
                end
            end
        end
    end

else
    function pdm -d "https://pdm-project.org"
        echo "Install https://pdm-project.org to use this plugin." > /dev/stderr
        return 1
    end
end
