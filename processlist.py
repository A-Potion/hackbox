import os

raw = os.open("data.txt", os.O_RDONLY)
processed = os.open("processed.txt", os.O_WRONLY | os.O_CREAT)

data = os.read(raw, 100000).decode('utf-8')
sentences = data.split('. ')

for sentence in sentences:
    sentence = sentence.strip()
    sentence = ' '.join(sentence.split())  # Remove all existing indentation
    if len(sentence) < 80 and len(sentence) > 25:
        os.write(processed, (sentence + '.\n').encode('utf-8'))

os.close(raw)
os.close(processed)