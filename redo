#! /bin/bash
REDO_API_HOST="http://redo.sh"

#Colors
RED='\033[0;31m'
NC='\033[0m' # No Color

mkdir -p ~/.redo
mkdir -p ~/.redo/commands
mkdir -p ~/.redo/private_commands


if [ $0 == "/usr/local/bin/redo-dev" ];
then
    REDO_API_HOST="http://localhost:8000"
fi

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
    local scriptfile=$HOME"/.redo/private_commands/"$1".sh"
    echo $scriptfile;
}


function REDO_scriptPath(){
    local scriptfile=$HOME"/.redo/commands/"$1".sh"
    echo $scriptfile;
}

function REDO_getCommandFromRemote(){ 
    local scriptfile=$(REDO_scriptPath $2)
    local remote_url=$REDO_API_HOST"/commands/"$2".sh"

    echo "> Fetching from remote..."
    REDO_http_code=$(curl -s -o "$scriptfile" "$remote_url" --write-out "%{http_code}")

    if [ $REDO_http_code == 200 ];
    then
        REDO_run $*
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

function REDO_run(){
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
REDO_getOs
command=$(echo "$1" | awk '{print tolower($0)}')

case $command in 
    run|r)
        REDO_run $*
        ;;
    edit|e)
        REDO_edit $*
        ;;
    *)
        REDO_run r $*
        ;;
esac
