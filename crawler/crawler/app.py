from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

def get_deezer_preview_url(track_id):
    api_url = f"https://api.deezer.com/track/{track_id}"
    resp = requests.get(api_url)
    if resp.status_code == 200:
        data = resp.json()
        return data.get("preview")
    else:
        return None

@app.route("/api/get-preview-url", methods=["POST"])
def get_preview_url():
    data = request.json
    track_id = data.get("trackId")
    if not track_id:
        return jsonify({"error": "Missing trackId"}), 400
    url = get_deezer_preview_url(track_id)
    if url:
        return jsonify({"previewUrl": url}), 200
    else:
        return jsonify({"error": "Not found"}), 404

if __name__ == "__main__":
    app.run(debug=True)