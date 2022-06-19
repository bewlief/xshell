

do_install() {
    local repo="ssh://git@github.com:codeforester/base.git"
    if [[ -d $BASE_HOME ]]; then
        if ((force_install)); then
            local base_home_backup=$BASE_HOME.$current_time
            if mv -- "$BASE_HOME" "$base_home_backup"; then
                printf '%s\n' "Moved current base home directory '$BASE_HOME' to '$base_home_backup'"
            else
                exit_if_error 1 "Couldn't move current base home directory '$BASE_HOME' to '$base_home_backup'"
            fi
        else
            printf '%s\n' "Base is already installed at '$BASE_HOME'"
            exit 0
        fi
    fi

    git clone "$repo" "$BASE_HOME"
    exit_if_error $? "Couldn't install Base"
    printf '%s\n' "Installed Base at '$BASE_HOME'"

    #
    # patch .baserc
    # This is how we remember custom BASE_HOME path and BASE_TEAM values.
    # The user is free to put custom code into the .baserc file.
    # A marker is appended to the lines managed by base CLI.
    #
    BASE_TEAM=$base_team
    BASE_SHARED_TEAMS=$base_shared_teams
    patch_baserc BASE_HOME BASE_TEAM BASE_SHARED_TEAMS

    exit 0
}


do_embrace() {
    if ! verify_base; then
        error_exit "$glb_error_message"
    fi
    local base_bash_profile=$BASE_HOME/lib/bash_profile
    local base_bashrc=$BASE_HOME/lib/bashrc
    local bash_profile=$HOME/.bash_profile
    local bashrc=$HOME/.bashrc
    if [[ -L $bash_profile ]]; then
        local bash_profile_link=$(readlink "$bash_profile")
    fi
    if [[ -L $bashrc ]]; then
        local bashrc_link=$(readlink "$bashrc")
    fi
    if [[ $bash_profile_link = $base_bash_profile ]]; then
        printf '%s\n' "$bash_profile is already symlinked to $base_bash_profile"
    else
        if [[ -f $bash_profile ]]; then
            local bash_profile_backup=$HOME/.bash_profile.$current_time
            printf '%s\n' "Backing up $bash_profile to $bash_profile_backup and overriding it with $base_bash_profile"
            if ! cp -- "$bash_profile" "$bash_profile_backup"; then
                exit_if_error $? "ERROR: can't create a backup of $bash_profile"
            fi
        fi
        if ln -sf -- "$base_bash_profile" "$bash_profile"; then
            printf '%s\n' "Symlinked '$bash_profile' to '$base_bash_profile'"
        fi
    fi
    if [[ $bashrc_link = $base_bashrc ]]; then
        printf '%s\n' "$bashrc is already symlinked to $base_bashrc"
    else
        if [[ -f $bashrc ]]; then
            local bashrc_backup=$HOME/.bashrc.$current_time
            printf '%s\n' "Backing up $bashrc to $bashrc_backup and overriding it with $base_bashrc"
            if ! cp -- "$bashrc" "$bashrc_backup"; then
                exit_if_error $? "ERROR: can't create a backup of $bashrc"
            fi
        fi
        if ln -sf -- "$base_bashrc" "$bashrc"; then
            printf '%s\n' "Symlinked '$bash_profile' to '$base_bash_profile'"
        fi
    fi
}

do_update() {
    if [[ -d $BASE_HOME ]]; then
        cd -- "$BASE_HOME" || error_exit "Can't cd to BASE_HOME at '$BASE_HOME'"
        git pull
    else
        printf '%s\n' "ERROR: Base is not installed at BASE_HOME '$BASE_HOME'"
        exit 1
    fi
}
