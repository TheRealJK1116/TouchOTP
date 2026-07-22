import base64

def custom_b32decode(base32_str):
    upper = base32_str.upper().replace(" ", "").rstrip("=")
    length = len(upper)
    
    data = bytearray()
    buffer = 0
    bits_left = 0
    
    for i in range(length):
        c = upper[i]
        val = 0
        if 'A' <= c <= 'Z':
            val = ord(c) - ord('A')
        elif '2' <= c <= '7':
            val = ord(c) - ord('2') + 26
            
        buffer = (buffer << 5) | val
        bits_left += 5
        
        if bits_left >= 8:
            byte = (buffer >> (bits_left - 8)) & 0xFF
            data.append(byte)
            bits_left -= 8
            
    return bytes(data)

secret = "JBSWY3DPEHPK3PXP"
print("Stdlib:", base64.b32decode(secret, True).hex())
print("Custom:", custom_b32decode(secret).hex())
