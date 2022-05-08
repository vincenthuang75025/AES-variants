f = open("input.txt", "w")

plaintext = "A"
while len(plaintext) < 2**20:
    print(1)
    plaintext = plaintext + plaintext

f.write(plaintext)

f.close()