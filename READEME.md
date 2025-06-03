# File Transfer Script

A simple bash script to transfer files securely between two Linux hosts using `socat`, `gzip`, `uuencode`, `openssl`, and `md5sum`.

---

## Features

- Send and receive files over TCP.
- Supports compression (gzip) and encoding (uuencode).
- Optional encryption and decryption with OpenSSL AES-256-CBC.
- Progress bar with `pv`.
- Integrity verification with MD5 checksum.
- Dependency check with `--deps`.
- Colored and user-friendly terminal UI.
- Save received file with a custom name (`--save-as`).
- Help and usage examples (`--help`).

---

## Requirements

Make sure the following commands/tools are installed on both sender and receiver:

- socat
- gzip
- uuencode / uudecode
- md5sum
- pv
- base64
- openssl
- bash

---

## Usage

### Send a file:

./file_transfer.sh --send <file> --host <receiver-ip> --port <port> [--encrypt <password>]

Example:

./file_transfer.sh --send myfile.txt --host 192.168.1.10 --port 8080 --encrypt secret123

### Receive a file:

./file_transfer.sh --receive --port <port> [--decrypt <password>] [--save-as <filename>]

Example:

./file_transfer.sh --receive --port 8080 --decrypt secret123 --save-as received.txt


## Options

 *   --send <file>: Send the specified file.
*    --receive: Receive a file.
*    --host <host>: The destination host IP or hostname (required for sending).
*    --port <port>: TCP port to send/receive on.
*    --encrypt <password>: Encrypt the data stream when sending.
*    --decrypt <password>: Decrypt the data stream when receiving.
*    --save-as <filename>: Save received file with this name instead of original.
*    --deps: Check if all required dependencies are installed.
*    --help: Show help message.

## Notes

 *   Make sure the chosen port is open and not blocked by firewalls.
*    Use strong passwords for encryption to secure your data.
*    Both sender and receiver must use the same password when encryption is enabled.
*    The script uses socat for TCP communication and cleans up temporary files automatically.
*    If a checksum mismatch occurs, the transfer might be corrupted.
	

Enjoy secure and reliable file transfers!