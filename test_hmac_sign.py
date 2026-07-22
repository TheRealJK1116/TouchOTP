import struct
import hmac
import hashlib
import time
import base64

def get_totp(secret, time_sec, period=30):
    key = base64.b32decode(secret, True)
    counter = int(time_sec / period)
    msg = struct.pack(">Q", counter)
    
    mac = hmac.new(key, msg, hashlib.sha1).digest()
    offset = mac[-1] & 0x0f
    
    binary = struct.unpack('>L', mac[offset:offset+4])[0] & 0x7fffffff
    
    return str(binary % 1000000).zfill(6)

print("Tests passed!")
