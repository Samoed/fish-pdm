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
    set -Ux __venv_loaded_vars $loaded_vars # Store the names in a universal variable for later use
end

# Function to check if any venv directory exists in the current directory
function __has_venv_directory
    # List of directories to check for virtual environments
    set -l venv_dirs "venv" ".venv" ".virtualenv" "env"

    for dir in $venv_dirs
        if test -e "$PWD/$dir"
            echo $dir
            return 0
        end
    end
    return 1
end

# Function to check if current directory is within a project root directory
function __is_subdir_of
    set -l current_path $PWD
    set -l project_root $argv[1]

    # Use string match to check if current path starts with project root
    string match -q "$project_root*" "$current_path"
    return $status
end

function __python_venv_activate --on-variable PWD
    if status --is-command-substitution
        return
    end

    # Check if we are in a directory with a venv
    set -l venv_dir (__has_venv_directory)
    set -l has_venv $status

    # If we have a venv in the current directory and no environment is active yet
    if test $has_venv -eq 0 && not set -q __python_venv_initial_pwd
        echo "Activating Python virtual environment..."
        set -gx __python_venv_initial_pwd "$PWD"
        set -gx __python_venv_root_dir "$PWD"

        # Check for activate.fish in the venv directory
        if test -e "$PWD/$venv_dir/bin/activate.fish"
            source "$PWD/$venv_dir/bin/activate.fish"
        else if test -e "$PWD/$venv_dir/Scripts/activate.fish"  # For Windows
            source "$PWD/$venv_dir/Scripts/activate.fish"
        else
            echo "Could not find activation script for Python virtual environment."
            set -e __python_venv_initial_pwd
            set -e __python_venv_root_dir
            return 1
        end

        # Load environment variables if .env file exists and FISH_VENV_LOAD_ENV is set
        if test "$FISH_VENV_LOAD_ENV" -a -e "$PWD/.env"
            echo "Setting environment variables from .env file..."
            posix-source $PWD/.env
        end
        return
    end

    # Deactivation check: only if we have moved outside the project root directory
    if set -q __python_venv_root_dir
        if not __is_subdir_of "$__python_venv_root_dir"
            # We've moved outside of the project directory, deactivate the environment
            if type -q deactivate
                deactivate
                echo "Python virtual environment deactivated."
            end

            set -e __python_venv_initial_pwd
            set -e __python_venv_root_dir

            # Clear the list of loaded variable names
            for var_name in $__venv_loaded_vars
                set -e $var_name
            end
            set -e __venv_loaded_vars
        end
    end
end
