import sys
import binascii

def guid_to_hex(guid):
    g = binascii.unhexlify(guid.translate(str.maketrans('','','-')))
    return ''.join(map(bytes.decode,map(binascii.hexlify, (g[3::-1],g[5:3:-1],g[7:5:-1],g[8:]))))

print(sys.argv[1])
print(guid_to_hex(sys.argv[1]))
