#!/bin/bash

# === Color UI ===
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# === Requirements ===
REQUIRED_CMDS=(socat gzip uuencode uudecode md5sum pv base64 openssl)

# === Functions ===

show_help() {
    echo -e "${BOLD}File Transfer Script using socat, base64, gzip, openssl and MD5${RESET}"
    echo -e "${CYAN}Usage:${RESET}"
    echo "  $0 --send <file> --host <host> --port <port> [--encrypt <password>]"
    echo "  $0 --receive --port <port> [--decrypt <password>] [--save-as <filename>]"
    echo "  $0 --deps         Check dependencies"
    echo "  $0 --help         Show this help"
    echo -e "${CYAN}Examples:${RESET}"
    echo "  $0 --send myfile.txt --host 192.168.1.10 --port 8080 --encrypt secret"
    echo "  $0 --receive --port 8080 --save-as received.txt --decrypt secret"
}

check_dependencies() {
    echo -e "${YELLOW}Checking required tools...${RESET}"
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Missing: $cmd${RESET}"
            MISSING=true
        else
            echo -e "${GREEN}Found: $cmd${RESET}"
        fi
    done
    if [ "$MISSING" = true ]; then
        echo -e "${RED}Some dependencies are missing. Install them and try again.${RESET}"
        exit 1
    else
        echo -e "${GREEN}All dependencies satisfied.${RESET}"
    fi
}

send_file() {
    local FILE="$1"
    local HOST="$2"
    local PORT="$3"
    local PASSWORD="$4"

    if [ ! -f "$FILE" ]; then
        echo -e "${RED}Error: File '$FILE' not found.${RESET}"
        exit 1
    fi

    echo -e "${CYAN}Compressing and encoding file...${RESET}"
    TMPFILE=$(mktemp)
    uuencode "$FILE" "$(basename "$FILE")" | gzip > "$TMPFILE"

    if [[ -n "$PASSWORD" ]]; then
        echo -e "${CYAN}Encrypting file...${RESET}"
        ENCRYPTED=$(mktemp)
        openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSWORD" -in "$TMPFILE" -out "$ENCRYPTED"
        mv "$ENCRYPTED" "$TMPFILE"
    fi

    MD5=$(md5sum "$TMPFILE" | awk '{print $1}')
    SIZE=$(stat -c %s "$TMPFILE")

    echo -e "${YELLOW}Sending to $HOST:$PORT ...${RESET}"
    {
        echo "$(basename "$FILE")"
        echo "$MD5"
        echo "$SIZE"
        pv "$TMPFILE"
        sleep 1
    } | base64 | socat - "TCP:$HOST:$PORT"

    echo -e "${GREEN}✅ Transfer completed successfully.${RESET}"
    rm -f "$TMPFILE"
}

receive_file() {
    local PORT="$1"
    local SAVE_AS="$2"
    local PASSWORD="$3"

    echo -e "${YELLOW}Listening on port $PORT ...${RESET}"
    socat - "TCP-LISTEN:$PORT,reuseaddr" | {
        base64 -d | {
            read -r NAME
            read -r EXPECTED_MD5
            read -r SIZE

            TMPFILE=$(mktemp)
            FILEOUT="${SAVE_AS:-$NAME}"

            echo -e "${CYAN}Receiving file: $FILEOUT${RESET}"
            pv -s "$SIZE" > "$TMPFILE"

            ACTUAL_MD5=$(md5sum "$TMPFILE" | awk '{print $1}')
            if [[ "$EXPECTED_MD5" != "$ACTUAL_MD5" ]]; then
                echo -e "${RED}WARNING: Checksum mismatch!${RESET}"
                echo -e "Expected: $EXPECTED_MD5"
                echo -e "Got     : $ACTUAL_MD5"
            else
                echo -e "${GREEN}Checksum OK ✅${RESET}"
            fi

            if [[ -n "$PASSWORD" ]]; then
                echo -e "${CYAN}Decrypting file...${RESET}"
                DECRYPTED=$(mktemp)
                openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PASSWORD" -in "$TMPFILE" -out "$DECRYPTED"
                mv "$DECRYPTED" "$TMPFILE"
            fi

            echo -e "${CYAN}Decoding and decompressing...${RESET}"
            gunzip -c "$TMPFILE" | uudecode -o "$FILEOUT"

            echo -e "${GREEN}✅ File saved as '$FILEOUT'${RESET}"
            rm -f "$TMPFILE"
        }
    }
}

# === Argument Parsing ===

MODE=""
FILE=""
HOST=""
PORT=""
SAVE_AS=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --send) MODE="send"; FILE="$2"; shift 2;;
        --receive) MODE="receive"; shift;;
        --host) HOST="$2"; shift 2;;
        --port) PORT="$2"; shift 2;;
        --save-as) SAVE_AS="$2"; shift 2;;
        --encrypt|--decrypt) PASSWORD="$2"; shift 2;;
        --deps) check_dependencies; exit 0;;
        --help) show_help; exit 0;;
        *) echo -e "${RED}Unknown argument: $1${RESET}"; show_help; exit 1;;
    esac
done

# === Execution ===
case "$MODE" in
    send)
        [ -z "$FILE" ] || [ -z "$HOST" ] || [ -z "$PORT" ] && { show_help; exit 1; }
        send_file "$FILE" "$HOST" "$PORT" "$PASSWORD"
        ;;
    receive)
        [ -z "$PORT" ] && { show_help; exit 1; }
        receive_file "$PORT" "$SAVE_AS" "$PASSWORD"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
