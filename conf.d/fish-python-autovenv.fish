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

function __python_venv_activate --on-variable PWD
    if status --is-command-substitution
        return
    end

    # Get current venv directory if any
    set -l venv_dir (__has_venv_directory)
    set -l has_venv $status

    # Deactivation check: if moving out of a directory with active venv, deactivate it
    if test $has_venv -ne 0
        if set -q __python_venv_initial_pwd
            # Check if 'deactivate' command exists and call it if so
            if type -q deactivate
                deactivate
                echo "Python virtual environment deactivated."
            end

            set -e __python_venv_initial_pwd

            # Clear the list of loaded variable names
            for var_name in $__venv_loaded_vars
                set -e $var_name
            end
            set -e __venv_loaded_vars
        end
        return
    end

    # Activation
    if test $has_venv -eq 0
        if not set -q __python_venv_initial_pwd
            echo "Activating Python virtual environment..."
            set -gx __python_venv_initial_pwd "$PWD"
            
            # Check for activate.fish in the venv directory
            if test -e "$PWD/$venv_dir/bin/activate.fish"
                source "$PWD/$venv_dir/bin/activate.fish"
            else if test -e "$PWD/$venv_dir/Scripts/activate.fish"  # For Windows
                source "$PWD/$venv_dir/Scripts/activate.fish"
            else
                echo "Could not find activation script for Python virtual environment."
                set -e __python_venv_initial_pwd
                return 1
            end

            # Load environment variables if .env file exists and FISH_VENV_LOAD_ENV is set
            if test "$FISH_VENV_LOAD_ENV" -a -e "$PWD/.env"
                echo "Setting environment variables from .env file..."
                posix-source $PWD/.env
            end
        end
    end
end
