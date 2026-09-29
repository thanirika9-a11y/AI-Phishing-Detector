import urllib.request
import json
import os

BASE_URL = "http://127.0.0.1:8000"

def upload_and_train(category, csv_bytes, filename="sample.csv"):
    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        f"Content-Type: text/csv\r\n\r\n"
    ).encode("utf-8") + csv_bytes + f"\r\n--{boundary}--\r\n".encode("utf-8")

    req = urllib.request.Request(
        f"{BASE_URL}/api/ml/upload-dataset?category={category}",
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"}
    )
    res = json.loads(urllib.request.urlopen(req).read().decode())
    print(f"Uploaded {category}: {res['success']} ({res['dataset_info']['total_rows']} rows)")

    train_req = urllib.request.Request(f"{BASE_URL}/api/ml/train?category={category}", method="POST")
    train_res = json.loads(urllib.request.urlopen(train_req).read().decode())
    best = train_res["best_model"]
    acc = train_res["models"][best]["accuracy"]
    print(f"Trained {category}: Best Model = {best} ({acc}% accuracy)")

def main():
    # 1. Train Spam using spam.csv
    spam_path = os.path.join(os.path.dirname(__file__), "datasets", "spam.csv")
    if os.path.exists(spam_path):
        with open(spam_path, "rb") as f:
            upload_and_train("spam", f.read(), "spam.csv")

    # 2. Train URL using phishing_urls_dataset.csv
    url_path = os.path.join(os.path.dirname(__file__), "datasets", "phishing_urls_dataset.csv")
    if os.path.exists(url_path):
        with open(url_path, "rb") as f:
            upload_and_train("url", f.read(), "phishing_urls_dataset.csv")

    # 3. Train Text, Email, Screenshot using sample generator
    for cat in ["text", "email", "screenshot"]:
        sample_url = f"{BASE_URL}/api/ml/sample-dataset?category={cat}"
        sample_csv = urllib.request.urlopen(sample_url).read()
        upload_and_train(cat, sample_csv, f"sample_{cat}.csv")

if __name__ == "__main__":
    main()
