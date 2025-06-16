import requests

url = "https://cdnt-preview.dzcdn.net/api/1/1/2/7/a/0/27a14827ff1e82c5e40e8b6a934a8637.mp3?hdnea=exp=1750089980~acl=/api/1/1/2/7/a/0/27a14827ff1e82c5e40e8b6a934a8637.mp3"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
}
resp = requests.get(url, headers=headers)

print("Status code:", resp.status_code)
if resp.status_code == 200:
    with open("preview.mp3", "wb") as f:
        f.write(resp.content)
    print("Tải file thành công, mở file preview.mp3 để kiểm tra.")
else:
    print("Lỗi khi tải:", resp.status_code)
    print(resp.text)