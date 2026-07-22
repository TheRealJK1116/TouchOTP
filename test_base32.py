import base64
import struct
import time
import hmac
import hashlib

def get_totp_token(secret_hex, intervals_no):
    key = base64.b32decode(secret_hex, True)
    msg = struct.pack(">Q", intervals_no)
    h = hmac.new(key, msg, hashlib.sha1).digest()
    o = h[19] & 15
    h = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000
    return "{:06d}".format(h)

secret = "JBSWY3DPEHPK3PXP"
current_time = int(time.time())
print("Expected:", get_totp_token(secret, int(current_time / 30)))
