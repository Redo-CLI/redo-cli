#! /bin/bash
# Docs available at: https://redo.sh/docs

COMMAND_DESCRIPTION="hello-world"

# Declare functions to be executed on different operating systems: UBUNTU, DEBIAN, RHEL, MACOS
# Comparators: gt = inclusive greater than,  lt = inclusive less than 
# Operators: and, or

#Ubuntu version 20 or newer
UBUNTU_gt_20="execute_linux"

#Debian version 20 or newer
DEBIAN_gt_20="execute_linux" 

#MacOS version 20 or newer
MACOS_gt_20="execute_maco"

# Functions
function execute_linux(){
    echo "Hello Lunux"
}

function execute_macos(){
    echo "Hello MacOs"
}
