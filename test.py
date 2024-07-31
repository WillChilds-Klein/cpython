import ssl
import socket

assert "AWS-LC" in ssl.OPENSSL_VERSION

ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.set_ecdh_curve("X25519Kyber768Draft00")
ctx.load_verify_locations("/etc/ssl/certs/ca-certificates.crt")

host = "secretsmanager.us-east-1.amazonaws.com"
sock = socket.create_connection((host, 443))
ssock = ctx.wrap_socket(sock, server_hostname=host)
ssock.close()
print("success!")
