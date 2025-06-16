import requests

url = "http://127.0.0.1:5000/api/get-preview-url"
payload = {"trackId": "1109731"}  # TrackID mẫu

resp = requests.post(url, json=payload)
print("Status code:", resp.status_code)
print("Kết quả trả về:", resp.json())