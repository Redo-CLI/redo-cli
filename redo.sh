#! /bin/bash
REDO_CLI_VERSION="1.0.1"

function REDO_config(){
    local val=$(cat -s $REDO_HOME"/config/"$1 2>/dev/null)
    if [ -z $val ];
    then
        #Define default configurations
        case $1 in 
            server-url)
                echo "https://redo.sh"
                ;;
        esac            
    else
        echo $val
    fi
}

REDO_API_HOST=$(REDO_config server-url)
REDO_HOME=$HOME"/.redo"

#Colors
RED='\033[0;31m'
NC='\033[0m' # No Color

mkdir -p $REDO_HOME
mkdir -p $REDO_HOME"/commands"
mkdir -p $REDO_HOME"/private_commands"
mkdir -p $REDO_HOME"/config"

if [ $0 == "/usr/local/bin/redo-dev" ];
then
    REDO_API_HOST="http://localhost:8000"
fi



function REDO_set_config(){
    echo $2 > $REDO_HOME"/config/"$1
}

function REDO_getOs(){
    local os=$(uname -s)
    local version=""

    if [ $os == "Darwin" ];
    then
        version=$(uname -r)
    else 
       source /etc/os-release
       os=$(lsb_release -si)
       version=$(lsb_release -sr)
    fi

    REDO_os=$(echo "$os" | awk '{print tolower($0)}')
    REDO_os_version=$(echo "$version" | awk '{print tolower($0)}')
}

function REDO_privateScriptPath(){
    local scriptfile=$REDO_HOME"/private_commands/"$1".sh"
    echo $scriptfile;
}


function REDO_scriptPath(){
    local scriptfile=$REDO_HOME"/commands/"$1".sh"
    echo $scriptfile;
}

function REDO_pull(){
    if [ -z $1 ];
    then
        echo "Usage: redo push <command>"
        echo "Error: <command> not found"
        exit
    fi

    echo "> Pull private command: "$1""

    local scriptfile=$(REDO_scriptPath $1)".tmp"
    local remote_url=$REDO_API_HOST"/commands/pull/"$1".sh"
    local apiToken=$(REDO_config api-token)

    REDO_http_code=$(curl -s -o "$scriptfile" "$remote_url" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --write-out "%{http_code}")
    
    if [ $REDO_http_code == 202  ];
    then
        if [ -e $REDO_HOME"/private_commands/$1.sh" ];
        then
            # Replace private command file only when $2 is not null
            if [ -n "${2}" ];
            then
                echo "Updated command file: "$1
                mv $scriptfile $REDO_HOME"/private_commands/$1.sh"            
            else
                echo "Not pulled, use --force to replace with current local version"
            fi
        else 
            # Create private command file
            echo "Created command file: "$1
            mv $scriptfile $REDO_HOME"/private_commands/$1.sh"
        fi
        return 0
    fi

}

function REDO_download(){ 
    local scriptfile=$(REDO_scriptPath $1)".tmp"
    local remote_url=$REDO_API_HOST"/commands/"$1".sh"
    local apiToken=$(REDO_config api-token)

    if [ -n "${3}" ];
    then
        echo "> Download private command: "$1""
    else
        echo "> Download public command: "$1""
    fi

    REDO_http_code=$(curl -s -o "$scriptfile" "$remote_url" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --write-out "%{http_code}")

    if [ $REDO_http_code == 202  ];
    then
        #Downloaded a private file
        if [ -e $REDO_HOME"/private_commands/$1.sh" ];
        then
            # Replace private command file only when $2 is not null
            if [ -n "${2:-1}" ];
            then
                mv $scriptfile $REDO_HOME"/private_commands/$1.sh"            
            fi
        else 
            # Create private command file
            mv $scriptfile $REDO_HOME"/private_commands/$1.sh"
        fi
        return 0
    elif [ $REDO_http_code == 200 ];
    then
        #Downloaded a public file        
        if [ -n "$3" ];
        then
            mv $scriptfile $REDO_HOME"/private_commands/$1.sh"            
        else
            mv $scriptfile $REDO_HOME"/commands/$1.sh"
        fi

        return 0
    elif [ $REDO_http_code == 401 ];
    then    
        rm -f $scriptfile
        echo "> Your API token has expired, please run: redo login"
        return 1
    else
        echo -e "> Command not available: "$1
        rm $scriptfile
        return 2
    fi
}

function REDO_execute(){
    local executeFunction=$(echo "REDO_$REDO_os" | awk '{print toupper($0)}')
    eval "local exectuable=\$$executeFunction"

    if [[ $(type -t $exectuable) == function ]];
    then 
        $exectuable
    elif [[ $(type -t $REDO_ALL) == function ]];
    then
        $REDO_ALL
    else
        echo "This command is not supported on your operating system: "$REDO_os
    fi
}

function REDO_help(){
    echo "Redo helps you do more without leaving the terminal."
    echo "Primany usage: redo <command> [<args>]"
    echo 
    echo "> 5 Basic Redo commands:"
    echo "redo <command> [<args>]       -     Run a command from the local repository, or download from remote."
    echo "redo edit <command>           -     Create or modify a custom private command."
    echo "redo search <qurery>          -     Find a command matching your query on the configured Redo server."
    echo "redo publish <command>        -     Publish the command publicly on the configured Redo server."
    echo "redo update [--force]         -     Sync your private and public commands with the configured Redo server. --force will replace all command files with remote version."
    echo
    echo "> Other Redo commands:"
    echo "redo login                    -     Log into Redo server account, required to push or publish commands."
    echo "redo push <command>           -     Push private command to the configured Redo server."
    echo "redo pull <command> [--force] -     Pull private command from the configured Redo server. --force will always replace local file with remote version"
    echo "redo configure <key> <val>    -     Modify redo configuration. keys: api-token, server-url."
    echo "redo clean                    -     Delete all local command files."
    echo "redo list|ls                  -     List all local commands."
    echo "redo upgrade                  -     Upgrade Redo CLI version."
    echo "redo help|-h                  -     Print built-in documnetation."
    echo "redo version|-v               -     Print Redo CLI version."
    echo 
    echo "System: "$REDO_os
    echo "System version: "$REDO_os_version
    echo "Redo version: "$REDO_CLI_VERSION
    echo "Redo server: "$REDO_API_HOST
}

function REDO_run(){
    if [ -z $2 ];
    then
        REDO_help
        exit
    fi

    local scriptfile=$(REDO_scriptPath $2)
    local privateScriptfile=$(REDO_privateScriptPath $2)

    if [ -e $privateScriptfile ];
    then
        source $privateScriptfile    
        REDO_execute
    elif [ -e $scriptfile ];
    then
        source $scriptfile    
        REDO_execute
    else 
        echo "> Redo command not found on local: "$2
        REDO_download $2
        local downloadstatus=$?
        if [ $downloadstatus -eq 0 ];
        then 
            REDO_run $*
        elif [ $downloadstatus -eq 2 ];
        then
            echo "> Use following commands to create and publish this command"
            echo
            echo "redo edit "$1
            echo "redo publish "$1
            echo
        fi
    fi
}

function REDO_open(){
    local editor=0
    echo "Please choose an editor to open the command file, default: vim"
    echo " [0] Vim"
    echo " [1] Nano"
    echo " [2] Visual Studio Code"
    read editor

    case $editor in
        2)
            code $1
            ;;
        1)
            nano $1
            ;;
        *)
            vi $1
        ;;
    esac
}

function REDO_edit(){
    if [ -z $2 ];
    then
        echo "Please specify a command name"
        exit
    fi

    local scriptfile=$(REDO_scriptPath $2)
    local privateScriptfile=$(REDO_privateScriptPath $2)
    local proceed="y"

    if [ -e $privateScriptfile ];
    then
        echo "Editing: "$privateScriptfile
        REDO_open $privateScriptfile
        echo 
        echo "> To sync this command privately: "        
        echo "redo push "$2 
        echo 
        echo "> To publish this command publicly: "        
        echo "redo publish "$2 
        echo
        exit  
    fi

    if [ -e $scriptfile ];
    then
        echo "Command already exists: "$2
        read -p "Do you wish to override this command, type y|n: " proceed
    fi

    case $proceed in 
        Y|y)
            curl -s -o $privateScriptfile $REDO_API_HOST"/commands/_sample.sh" "$remote_url"
            REDO_open $privateScriptfile
            echo "Command created! "
            echo "Edit following file to make changes to your command: "
            echo $privateScriptfile
            echo
            echo "> To sync this command privately: "        
            echo "redo push "$2 
            echo 
            echo "> To publish this command publicly: "        
            echo "redo publish "$2     
            echo    
            ;;
        *)
            echo "Aborted!"
            ;;
    esac
}

function REDO_login(){
    local apiToken

    echo "Visit: "$REDO_API_HOST"/api-token and copy your API token"
    read -p "Paste API token here: " apiToken

    echo "Validating API token..."
    local remote=$REDO_API_HOST"/api/me"
    local httpCode=$(curl --location -s -o /dev/null --request GET "$remote" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --write-out "%{http_code}")

    if [ $httpCode == 200 ];
    then
        REDO_set_config api-token $apiToken
        echo "Login succeeded!"        
    else
        echo "Invalid API token, HTTP CODE: "$httpCode
    fi

    exit
}

function REDO_check_auth(){
    local apiToken=$(REDO_config api-token)

    if [ -z $apiToken ];
    then
        echo "You need to login first!"
        REDO_login
    else
        local remote=$REDO_API_HOST"/api/me"
        local httpCode=$(curl --location -s -o /dev/null --request GET "$remote" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --write-out "%{http_code}")
        if [ $httpCode == 401 ];
        then
            echo "You API token has expired!"
            REDO_login
        fi
    fi

}

function REDO_publish(){
    if [ -z $1 ];
    then
        echo "Usage: redo publish <command>"
        echo "Error: <command> not found"
        exit
    fi

    REDO_check_auth

    local apiToken=$(REDO_config api-token)

    #Upload command
    local privateScriptfile=$(REDO_privateScriptPath $1)
    
    if [ -e $privateScriptfile ];
    then
        curl -sS --location --request POST "$REDO_API_HOST/api/commands/$1" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --form "script=@\"$privateScriptfile\"" --form "is_private_push=\"$2\""
    else 
        echo -e "${RED}> Private command \"$1\" does not exist on local disk"
        echo "> If you are publisher of this command, try again after: redo update"
        exit
    fi
}

function REDO_upload(){
    local privateScriptfile=$(REDO_privateScriptPath $1)
    if [ -z $1 ];
    then 
        echo "Usage: redo push <command>"
        echo "Error: <command> not found"
        exit
    fi

    if [ -e $privateScriptfile ];
    then
        REDO_check_auth

        #publish privately
        local status="$(REDO_publish $1 1)"
        echo "> Push "$1": "$status
    elif [ -n "$2" ];
    then    
        echo -e "${RED}> Private command \"$1\" does not exist on local disk"
        echo "> If you are publisher of this command, try again after: redo update"        
    fi
}

function REDO_pull_private_commands(){
    local apiToken=$(REDO_config api-token)
    local commandList=$(curl -s --location --request GET "$REDO_API_HOST/api/me/commands" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken")
    local cmd

    # Pull local commands
    for cmd in ${commandList[@]}
    do
        REDO_pull $cmd "$1" 
    done
}

function REDO_update(){
    REDO_check_auth
    local apiToken=$(REDO_config api-token)

    local commandList=$(curl -s --location --request GET "$REDO_API_HOST/api/me/commands" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken")
    local cmd

    # Push local commands
    for cmd in ${commandList[@]}
    do
        REDO_upload $cmd
    done

    REDO_pull_private_commands $1
    
    # Re-download remote commands
    local dir=$REDO_HOME'/commands/'
    local file="*.sh"
    for file in `cd ${dir};ls -1 ${file} 2>/dev/null` ;do
        cmd="${file%%.*}"
        REDO_download $cmd $1
    done
}

function REDO_search(){
    
    local results=$(curl -s --location --request GET "$REDO_API_HOST/commands/search?q=$1" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken")
    if [ -z "$results" ];
    then
        echo "No matching commands found for: "$1
    else 
        echo "$results"
    fi
}   

function REDO_configure(){
    if [ -z $2 ];
    then
        echo "Usage: redo configure <key> <value>"
        echo "Error: <key> not found"
        exit
    fi

    if [ -z $3 ];
    then
        echo "Usage: redo configure <key> <value>"
        echo "Error: <value> not found"
        exit
    fi

    case $2 in 
        api-token)
            REDO_set_config api-token $3
            echo "API Token updated!"
            ;;
        server-url)
            REDO_set_config server-url $3
            echo "Redo server URL updated!"
            ;;
        *)
            echo "Invalid configuration key, type redo -h to list all valid config keys."
            ;;
    esac

}

function REDO_ls(){
    echo "Available commands on your local disk:"
    echo 
    echo "Public commands in: "$REDO_HOME'/commands/'
    local dir=$REDO_HOME'/commands/'
    local file="*.sh"
    for file in `cd ${dir};ls -1 ${file} 2>/dev/null` ;do
        cmd="${file%%.*}"
        echo "- redo "$cmd
    done

    echo 
    echo "Private commands in: "$REDO_HOME'/private_commands/'
    local dir=$REDO_HOME'/private_commands/'
    local file="*.sh"
    for file in `cd ${dir};ls -1 ${file} 2>/dev/null` ;do
        cmd="${file%%.*}"
        echo "- redo "$cmd
    done

}

function REDO_clean(){
    rm -fr  "$REDO_HOME/commands"
    rm -fr "$REDO_HOME/private_commands"

    mkdir -p "$REDO_HOME/commands"
    mkdir -p "$REDO_HOME/private_commands"

    echo "All local commands were cleared"
    exit
}

REDO_getOs
echo
command=$(echo "$1" | awk '{print tolower($0)}')

case $command in 
    edit)
        REDO_edit $*
        ;;
    search)
        REDO_search $2
        ;;
    publish)
        REDO_publish $2
        ;;
    update)
        REDO_update $2
        ;;
    login)
        REDO_login
        ;;
    push)
        REDO_upload $2 --show-error
        ;;
    pull)
        REDO_pull $2 "$3"
        ;;
    configure)
        REDO_configure $*
        ;;
    clean)
        REDO_clean
        ;;
    list|ls)
        REDO_ls
        ;;
    upgrade)
        curl -fsSL https://get.redo.sh | bash
        ;;
    help|-h)
        REDO_help
        ;;
    version|-v)
        echo "Redo CLI v"$REDO_CLI_VERSION
        ;;
    *)
        REDO_run r $*
        ;;
esac
echo