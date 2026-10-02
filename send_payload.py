"""Sends a payload ELF to a PS5's ELF loader (port 9021) and prints what the payload writes back.

    python send_payload.py simpleFPS.elf <PS5 address> [seconds to listen]
"""
import socket
import sys


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    host = sys.argv[2]
    listen = float(sys.argv[3]) if len(sys.argv) > 3 else 5
    data = open(sys.argv[1], 'rb').read()
    with socket.create_connection((host, 9021), timeout=5) as s:
        s.sendall(data)
        s.shutdown(socket.SHUT_WR)
        s.settimeout(listen)
        try:
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                sys.stdout.write(chunk.decode('utf-8', 'replace'))
        except socket.timeout:
            pass


if __name__ == '__main__':
    main()
