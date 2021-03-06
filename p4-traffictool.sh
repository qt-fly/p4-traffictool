#!/bin/bash

# exit codes
#   1 incorrect file specification
#   2 incorrect argument specification
#   3 p4 compilation error

usage(){
    echo "Usage: p4-traffictool.sh [-h|--help] [-p4 <path to p4 source>] [-json <path to json description>] [--std {p4-14|p4-16}] [-o <path to destination dir>] [--scapy] [--wireshark] [--moongen] [--pcpp] [--debug]"
    exit $1
}

print_arguments(){
    echo -e "------------------------------------"
    echo "P4_SOURCE $P4_SOURCE"
    echo "JSONSOURCE $JSONSOURCE"
    echo "SCAPY $SCAPY"
    echo "WIRESHARK $WIRESHARK"
    echo "PCAPPLUSPLUS $PCAPPLUSPLUS"
    echo "MOONGEN $MOONGEN"
    echo "STANDARD $STANDARD"
    echo "DEBUG_MODE $DEBUG_MODE"
    echo "OUTPUT DIR $OUTPUT"
    echo -e "------------------------------------\n"

}


# if no arguments are specified then show usage
if ([[ "$#" == "0" ]]); then
    usage 0
fi

JSON_DETECT=false
P4_DETECT=false
OUT_DETECT=false
SCAPY=false
WIRESHARK=false
MOONGEN=false
PCAPPLUSPLUS=false
DEBUG_MODE=false
STANDARD="p4-16"

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            usage 0
            ;;
        -p4)
            shift
            if test $# -gt 0; then
                P4_DETECT=true
                P4_SOURCE=$(realpath $1)
                shift    
            else
                echo "P4 source not found"
                usage 1
            fi
            ;;
        -json)
            shift
            if test $# -gt 0; then
                JSON_DETECT=true
                JSONSOURCE=$(realpath $1)
                shift    
            else
                echo "JSON source not found"
                usage 1
            fi
            ;;
        -o)
            shift
            if test $# -gt 0; then
                OUT_DETECT=true
                OUTPUT=$1
                shift    
            else
                echo "output flag given but directory not specified"
                usage 1
            fi
            ;;
        --std)
            shift
            if test $# -gt 0; then
                STANDARD=$1
                shift    
            else
                echo "Standard flag given, but standard not specified, use p4-14 OR p4-16"
                usage 2
            fi
            ;;
        --scapy)
            shift
            SCAPY=true
            ;;    
        --wireshark)
            shift
            WIRESHARK=true
            ;;
        --moongen)
            shift
            MOONGEN=true
            ;;
        --pcpp)
            shift
            PCAPPLUSPLUS=true
            ;;
        --debug)
            shift
            DEBUG_MODE=true
            ;;
        *)
            echo "Unknown argument $1"
            usage 2
            ;;  
    esac
done

if [[ "$DEBUG_MODE" = true ]]; then
    print_arguments
fi

if [[ "$JSON_DETECT" = false && "$P4_DETECT" = false ]]; then
    echo "No source specified"
    usage 2
fi

if [[ "$SCAPY" = false  &&  "$MOONGEN" = false &&  "$PCAPPLUSPLUS" = false &&  "$WIRESHARK" = false ]] ; then
    echo "No Target specified"
    while true; do
        read -p "Do you wish to generate Scapy code? [y/n] " yn
        case $yn in
            [Yy]* ) SCAPY=true; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    while true; do
        read -p "Do you wish to generate MoonGen code? [y/n] " yn
        case $yn in
            [Yy]* ) MOONGEN=true; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    while true; do
        read -p "Do you wish to generate WireShark code? [y/n] " yn
        case $yn in
            [Yy]* ) WIRESHARK=true; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    while true; do
        read -p "Do you wish to generate PcapPlusPlus code? [y/n] " yn
        case $yn in
            [Yy]* ) PCAPPLUSPLUS=true; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    # SCAPY=true
    # MOONGEN=true
    # PCAPPLUSPLUS=true
    # WIRESHARK=true
fi

if [[ "$SCAPY" = false  &&  "$MOONGEN" = false &&  "$PCAPPLUSPLUS" = false &&  "$WIRESHARK" = false ]] ; then
    exit 0
fi

if [ "$JSON_DETECT" = false ]; then
    # creates a temp folder with timestamp to hold json script and compiled binaries
    foldername="`date +%Y%m%d%H%M%S`";
    foldername="tempfolder_$foldername"
    jsonname=$(basename -- "$P4_SOURCE")
    jsonname="${jsonname%.*}.json"
    mkdir $foldername
    cd $foldername

    # p4 source compilation
    echo -e "----------------------------------\nCompiling p4 source ..."
    p4c-bm2-ss --std $STANDARD -o $jsonname $P4_SOURCE > /dev/null 2>&1
    if [ $? != "0" ]; then
        echo "Compilation with p4c-bm2-ss failed...trying with p4c"
        p4c -S --std $STANDARD $P4_SOURCE > /dev/null 2>&1
        if [ $? != "0" ]; then
            echo "Compilation with p4c failed.. exiting"
            cd ..
            rm -r $foldername
            exit 3
        else
            echo "Compilation successful with p4c"
        fi

    else
        echo "Compilation successful with p4c-bm2-ss"
    fi
    echo -e "------------------------------------\n"
    
    JSONSOURCE=$(find . -name "*.json" -type f)
    JSONSOURCE=$(realpath $JSONSOURCE)
    cd ..
    if ([ "$OUT_DETECT" = false ]);then
        OUTPUT=$(dirname "$P4_SOURCE")
        echo -e "Using the directory of source as default destination directory\n"
    fi
else
    if ([ "$OUT_DETECT" = false ]);then
        OUTPUT=$(dirname "$JSONSOURCE")
        echo -e "Using the directory of source as default destination directory\n"
    fi

fi

# DIR stores the path to p4-traffictool script, this is required for calling backend scripts
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 

if [[ "$DEBUG_MODE" = true ]]; then
    DEBUG_MODE="-d"
else
    DEBUG_MODE=""
fi
mkdir -p "$OUTPUT"
# running backend scripts
if [[ "$SCAPY" = true ]];then
    temp="$OUTPUT/scapy"
    echo "Running Scapy backend script"
    mkdir -p $temp
    python $DIR/src/GenTrafficScapy.py $JSONSOURCE $temp $DEBUG_MODE
    echo -e "------------------------------------\n"
fi
if [[ "$WIRESHARK" = true ]];then
    temp="$OUTPUT/wireshark"
    echo "Running Lua dissector backend script"
    mkdir -p $temp
    python $DIR/src/DissectTrafficLua.py $JSONSOURCE $temp $DEBUG_MODE
    echo -e "------------------------------------\n"
fi
if [[ "$MOONGEN" = true ]];then
    temp="$OUTPUT/moongen"
    echo "Running MoonGen backend script"
    mkdir -p $temp
    python $DIR/src/GenTrafficMoonGen.py $JSONSOURCE $temp $DEBUG_MODE
    echo -e "------------------------------------\n"
fi
if [[ "$PCAPPLUSPLUS" = true ]];then
    temp="$OUTPUT/pcapplusplus"
    echo "Running PcapPlusPlus backend script"
    mkdir -p $temp
    python $DIR/src/DissectTrafficPcap.py $JSONSOURCE $temp $DEBUG_MODE
    echo -e "------------------------------------\n"
fi

# remove tempfolder created
if [[ "$JSON_DETECT" = false ]]; then
    rm -rf $foldername
fi
