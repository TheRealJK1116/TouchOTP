import hmac
import hashlib
import struct

key = bytes.fromhex("48656c6c6f21deadbeef")
msg = struct.pack(">Q", 59616053)

h = hmac.new(key, msg, hashlib.sha1).digest()
print("Hash hex:", h.hex())

o = h[19] & 15
print("Offset:", o)

truncated = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff)
print("Truncated:", truncated)

pin = truncated % 1000000
print("PIN:", pin)
