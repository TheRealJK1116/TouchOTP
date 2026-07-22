import hmac
import hashlib
import struct

def gen(secret_bytes, timestamp, period, digits):
    counter = int(timestamp / period)
    msg = struct.pack(">Q", counter)
    mac = hmac.new(secret_bytes, msg, hashlib.sha1).digest()
    offset = mac[-1] & 0x0f
    binary = struct.unpack('>I', mac[offset:offset+4])[0] & 0x7fffffff
    return str(binary % (10**digits)).zfill(digits)

print(gen(bytes.fromhex("48656c6c6f21deadbeef"), 59616053 * 30, 30, 6))
