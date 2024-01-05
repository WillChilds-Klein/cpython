import csv
import hashlib
import multiprocessing
import socket
import ssl
import time


HOSTNAME = "127.0.0.1"
SERVER_PORT = 4433

HASHES = [
    "md5",
    "sha1",
    "sha256",
    "sha384",
    "sha512",
    "sha3_256",
    "sha3_384",
    "sha3_512",
]


def main():
    server = multiprocessing.Process(target=start_server, daemon=True)
    server.start()
    time.sleep(0.5)  # the server takes a little time to get going.
    print(f"OPENSSL VERSION: {ssl.OPENSSL_VERSION}")
    print(f"{'ALGO':^10} {'SIZE (B)':^10} {'TIME (s)':^20}")
    print(f"{'====':^10} {'========':^10} {'========':^20}")
    for size in 0, 1024, 1024**2:
        times = [run_client(size) for _ in range(1000)]
        print(f"{'TLS':<10} {size:<10} {sum(times)/len(times):<20}")
    for h in HASHES:
        for size in 8, 1024, 1024**2:
            times = [do_hash(h, size) for _ in range(1000)]
            print(f"{h:<10} {size:<10} {sum(times)/len(times):<20}")
    print()


def do_hash(h: str, size: int) -> int:
    start = time.time()
    digest = hashlib.new(h)
    digest.update(b"X" * size)
    digest.digest()
    end = time.time()
    return end - start


def run_client(size: int) -> int:
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ctx.load_verify_locations("./bench/certs/CA.crt")
    ctx.check_hostname = False
    start = time.time()
    with ctx.wrap_socket(socket.socket(socket.AF_INET)) as conn:
        conn.connect((HOSTNAME, SERVER_PORT))
        if size > 0:
            conn.sendall(b"X" * size)
    end = time.time()
    return end - start


def start_server():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("./bench/certs/server.crt", "./bench/certs/server.key")
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0) as sock:
        sock.bind((HOSTNAME, SERVER_PORT))
        sock.listen()
        with ctx.wrap_socket(sock, server_side=True) as ssock:
            while True:
                try:
                    conn, addr = ssock.accept()
                except ssl.SSLEOFError:
                    continue
                data = conn.recv(1024)
                while data:
                    data = conn.recv(1024)


if __name__ == "__main__":
    main()
