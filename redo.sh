#! /bin/bash
function REDO_config(){
    local val=$(cat -s $REDO_HOME"/config/"$1 2>/dev/null)
    if [ -z $val ];
    then
        #Define default configurations
        case $1 in 
            server-url)
                echo "http://redo.sh"
                ;;
        esac            
    else
        echo $val
    fi
}

REDO_CLI_VERSION="1.0.0"
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

function REDO_getCommandFromRemote(){ 
    local scriptfile=$(REDO_scriptPath $2)
    local remote_url=$REDO_API_HOST"/commands/"$2".sh"
    local apiToken=$(REDO_config api-token)

    echo "> Fetching from remote..."
    REDO_http_code=$(curl -s -o "$scriptfile" "$remote_url" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --write-out "%{http_code}")

    if [ $REDO_http_code == 200 ];
    then
        REDO_run $*
    elif [ $REDO_http_code == 202 ];
    then
        mv $scriptfile $REDO_HOME"/private_commands/"
        REDO_run $*
    elif [ $REDO_http_code == 401 ];
    then    
        rm -f $scriptfile
        echo "> Your API token has expired, please run: redo login"
    else
        echo -e "${RED}> Command not available: "$2
        echo "> Use following commands to create and publish this command"
        echo
        echo "redo edit "$2
        echo "redo publish "$2
        echo
        rm $scriptfile
    fi
}

function REDO_execute(){
    case $REDO_os in 
    darwin)
        $REDO_DARWIN
        ;;
    ubuntu)
        $REDO_UBUNTU
        ;;
    debian)
        $REDO_DEBIAN
        ;;
    rhel)
        $REDO_RHEL
        ;;
    *)
        echo "This command is not supported on "$REDO_os
        ;;
    esac
}

function REDO_help(){
    echo "Redo helps you do more without leaving the terminal."
    echo
    echo "Primany usage: redo <command> [<args>]"
    echo 
    echo "5 Basic redo commands:"
    echo "redo <command> [<args>]       -     Run a command from the local repository, or download from remote."
    echo "redo edit|e <command>         -     Create or modify a custom private command."
    echo "redo publish|p <command>      -     Publish the command publicly, to the configured Redo server."
    echo "redo search|s <qurery>        -     Find a command matching your query on the configured Redo server."
    echo "redo update|u                 -     Sync your private and public commands with the configured Redo server."
    echo
    echo "Other redo commands:"
    echo "redo configure|c <key> <val>  -     Modify redo configuration. keys: api-token, server-url."
    echo "redo help|-h <key> <val>      -     Print built-in documnetation."
    echo 
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
        REDO_getCommandFromRemote $*
    fi
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
        open -e $privateScriptfile
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
            open -e $privateScriptfile
            echo "Edit following file to make changes to your command: "
            echo $privateScriptfile
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
    local isPrivateFlag="--form 'is_private=\"1\"'"

    if [ -z $2 ];
    then
        isPrivateFlag=""
    fi

    if [ -e $privateScriptfile ];
    then
        curl --location --request POST "http://localhost:8000/api/commands/$1" --header 'Accept: application/json' --header "Authorization: Bearer $apiToken" --form "script=@\"$privateScriptfile\"" --form "is_private=\"$2\""
    else 
        echo -e "${RED}> Private command \"$1\" does not exist on local disk"
        echo "> If you are publisher of this command, try again after: redo update"
        exit
    fi
}

function REDO_update(){
    REDO_publish t 1
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


REDO_getOs
command=$(echo "$1" | awk '{print tolower($0)}')

case $command in 
    edit|e)
        REDO_edit $*
        ;;
    configure|c)
        REDO_configure $*
        ;;
    publish|p)
        REDO_publish $2
        ;;
    update|u)
        REDO_update
        ;;
    login|l)
        REDO_login
        ;;
    help|-h)
        REDO_help
        ;;
    *)
        REDO_run r $*
        ;;
esac
