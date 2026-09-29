import pandas as pd
import numpy as np
import re
import json
from urllib.parse import urlparse
import io

# ─────────────────────────────────────────────
# Feature Engineering
# ─────────────────────────────────────────────

SUSPICIOUS_TLDS = {"xyz", "top", "club", "work", "ru", "cc", "click", "link", "bid",
                   "loan", "men", "gq", "cf", "ml", "tk", "date", "stream", "download"}

SENSITIVE_KEYWORDS = ["paypal", "netflix", "amazon", "bank", "login", "signin",
                      "verify", "secure", "verification", "billing", "update",
                      "account", "support", "credential", "suspend", "security"]

def extract_features_from_url(url: str) -> dict:
    """Extract numeric features from a single URL string."""
    try:
        parsed = urlparse(url if "://" in url else f"http://{url}")
        hostname = parsed.hostname or ""
        path = parsed.path or ""
        full = url.lower()
    except Exception:
        hostname, path, full = "", "", url.lower()

    tld = hostname.split(".")[-1] if "." in hostname else ""

    return {
        "url_length":           len(url),
        "hostname_length":      len(hostname),
        "path_length":          len(path),
        "num_dots":             url.count("."),
        "num_hyphens":          url.count("-"),
        "num_at":               url.count("@"),
        "num_question":         url.count("?"),
        "num_equals":           url.count("="),
        "num_underscores":      url.count("_"),
        "num_slashes":          url.count("/"),
        "num_digits":           sum(c.isdigit() for c in url),
        "digit_ratio":          round(sum(c.isdigit() for c in url) / max(len(url), 1), 4),
        "has_https":            int(url.lower().startswith("https")),
        "has_ip":               int(bool(re.search(r"\d{1,3}(\.\d{1,3}){3}", hostname))),
        "subdomain_count":      max(0, len(hostname.split(".")) - 2),
        "is_suspicious_tld":    int(tld in SUSPICIOUS_TLDS),
        "sensitive_keyword_ct": sum(kw in full for kw in SENSITIVE_KEYWORDS),
        "has_login_keyword":    int(any(kw in full for kw in ["login", "signin", "verify"])),
        "has_brand_keyword":    int(any(kw in full for kw in ["paypal", "netflix", "amazon", "bank"])),
    }

def extract_features_from_text(text: str) -> dict:
    """Extract numeric features from a raw text message."""
    text_lower = text.lower()
    words = text.split()
    num_words = len(words)
    
    urgency_count = sum(1 for p in [r"action", r"suspended", r"unauthorized", r"urgent", r"immediately", r"within", r"final", r"breach", r"reactivate", r"verify"] if p in text_lower)
    scam_count = sum(1 for p in [r"won", r"prize", r"lottery", r"gift", r"cash", r"refund", r"wire", r"free", r"claim"] if p in text_lower)
    cred_count = sum(1 for p in [r"password", r"otp", r"pin", r"credit", r"bank", r"cvv", r"cvc"] if p in text_lower)
    
    has_links = int("http://" in text_lower or "https://" in text_lower or "www." in text_lower or ".com" in text_lower or ".net" in text_lower)
    
    uppercase_count = sum(1 for c in text if c.isupper())
    digit_count = sum(1 for c in text if c.isdigit())
    special_count = sum(1 for c in text if c in "$%!@#&*?")
    
    return {
        "text_length": len(text),
        "num_words": num_words,
        "uppercase_ratio": round(uppercase_count / max(len(text), 1), 4),
        "digit_ratio": round(digit_count / max(len(text), 1), 4),
        "special_ratio": round(special_count / max(len(text), 1), 4),
        "has_links": has_links,
        "urgency_score": urgency_count,
        "scam_score": scam_count,
        "cred_score": cred_count,
        "is_all_caps": int(text.isupper() and len(text) > 5)
    }

FEATURE_COLUMNS = list(extract_features_from_url("http://example.com").keys())

def parse_arff_bytes(file_bytes: bytes) -> pd.DataFrame:
    """Parse Weka ARFF file bytes into a pandas DataFrame."""
    text = file_bytes.decode("utf-8", errors="ignore")
    lines = text.splitlines()

    attributes = []
    data_lines = []
    in_data = False

    for line in lines:
        line_clean = line.strip()
        if not line_clean or line_clean.startswith("%"):
            continue

        if line_clean.lower().startswith("@attribute"):
            parts = line_clean.split()
            if len(parts) >= 2:
                # attr name is second word (remove quotes if present)
                attr_name = parts[1].strip("'\"")
                attributes.append(attr_name)
        elif line_clean.lower().startswith("@data"):
            in_data = True
        elif in_data:
            data_lines.append(line_clean)

    if not data_lines:
        raise ValueError("Invalid ARFF file: no @data section found.")

    csv_data = "\n".join(data_lines)
    if attributes:
        df = pd.read_csv(io.StringIO(csv_data), header=None, names=attributes)
    else:
        df = pd.read_csv(io.StringIO(csv_data))

    return df

def load_and_preprocess(file_bytes: bytes, filename: str = "") -> tuple:
    """
    Load CSV or ARFF bytes and return (DataFrame with features, labels array, raw_df, info_dict).
    Handles multiple common column naming conventions.
    """
    if filename.lower().endswith(".arff") or b"@relation" in file_bytes[:1000] or b"@data" in file_bytes[:2000]:
        raw_df = parse_arff_bytes(file_bytes)
    else:
        raw_df = pd.read_csv(io.BytesIO(file_bytes))

    # ── Detect URL or Text column ──
    url_col = None
    text_col = None
    
    for candidate in ["url", "URL", "Url", "link", "Link", "domain", "Domain", "uri", "URI", "web_url"]:
        if candidate in raw_df.columns:
            url_col = candidate
            break
            
    for candidate in ["text", "Text", "message", "Message", "sms", "SMS", "body", "Body", "email", "Email", "v2", "content", "Content", "subject", "Subject", "clean_text", "tweet", "header", "Header", "ocr_text", "caption"]:
        if candidate in raw_df.columns:
            text_col = candidate
            break

    if url_col is None and text_col is None:
        for col in raw_df.columns:
            if raw_df[col].dtype == object:
                sample_vals = raw_df[col].dropna().head(10).astype(str)
                is_url = any("://" in val or "www." in val for val in sample_vals)
                if is_url:
                    url_col = col
                else:
                    text_col = col
                break

    # ── Detect label column ──
    label_col = None
    for candidate in ["label", "Label", "result", "Result", "status", "Status",
                      "class", "Class", "target", "Target", "phishing", "Phishing",
                      "category", "Category", "v1", "v1_label", "spam", "Spam", "type", "Type", "fraud", "Fraud"]:
        if candidate in raw_df.columns:
            label_col = candidate
            break
    if label_col is None:
        raise ValueError("Cannot detect label column. Ensure CSV has a 'label', 'Category', 'Class', 'spam', or 'result' column.")

    # ── Normalise labels → 0 (legitimate) / 1 (phishing) ──
    raw_df = raw_df.dropna(subset=[label_col])
    lv = raw_df[label_col].astype(str).str.strip().str.lower()
    label_map = {
        "1": 1, "phishing": 1, "phish": 1, "bad": 1, "malicious": 1, "spam": 1, "fraud": 1, "true": 1, "yes": 1, "smishing": 1, "vishing": 1,
        "0": 0, "legitimate": 0, "legit": 0, "good": 0, "benign": 0, "ham": 0, "normal": 0, "false": 0, "no": 0,
        "-1": 0,
    }
    raw_df["_label_"] = lv.map(label_map)
    raw_df = raw_df.dropna(subset=["_label_"])
    raw_df["_label_"] = raw_df["_label_"].astype(int)

    # ── Extract features from URL/Text column or use existing numeric cols ──
    numeric_cols = raw_df.select_dtypes(include=[np.number]).columns.tolist()
    numeric_cols = [c for c in numeric_cols if c != "_label_" and c != label_col]

    if url_col and len(numeric_cols) < 5:
        # Build features from URL strings
        features_list = raw_df[url_col].fillna("").apply(extract_features_from_url).tolist()
        feature_df = pd.DataFrame(features_list)
    elif text_col and len(numeric_cols) < 5:
        # Build features from general text strings
        features_list = raw_df[text_col].fillna("").apply(extract_features_from_text).tolist()
        feature_df = pd.DataFrame(features_list)
    else:
        # Dataset already has numeric feature columns (like UCI phishing dataset)
        feature_df = raw_df[numeric_cols].copy()
        feature_df = feature_df.replace(-1, 0)

    labels = raw_df["_label_"].values

    info = {
        "total_rows":      int(len(raw_df)),
        "total_cols":      int(len(raw_df.columns)),
        "url_column":      url_col,
        "label_column":    label_col,
        "feature_count":   int(len(feature_df.columns)),
        "phishing_count":  int((labels == 1).sum()),
        "legit_count":     int((labels == 0).sum()),
        "class_balance":   round(float((labels == 1).sum()) / max(len(labels), 1) * 100, 2),
        "sample_urls":     raw_df[url_col].head(5).tolist() if url_col else [],
    }

    return feature_df, labels, raw_df, info


# ─────────────────────────────────────────────
# EDA Statistics Generator
# ─────────────────────────────────────────────

def generate_eda(raw_df: pd.DataFrame, labels: np.ndarray, url_col: str | None, info: dict) -> dict:
    """Generate all EDA chart data as JSON-serialisable dicts."""

    # 1. Label distribution
    label_dist = {
        "phishing":    int(info["phishing_count"]),
        "legitimate":  int(info["legit_count"]),
    }

    # 2. URL length distribution (buckets of 20)
    url_lengths = []
    if url_col and url_col in raw_df.columns:
        lengths = raw_df[url_col].fillna("").str.len()
        bins = list(range(0, 201, 20)) + [999]
        labels_bins = [f"{b}-{bins[i+1]}" for i, b in enumerate(bins[:-1])]
        hist, _ = np.histogram(lengths.clip(upper=200), bins=bins)
        url_lengths = [{"range": labels_bins[i], "count": int(hist[i])} for i in range(len(hist))]

    # 3. Top TLDs (phishing vs legit)
    tld_stats = {}
    if url_col and url_col in raw_df.columns:
        df_temp = raw_df[[url_col, "_label_"]].copy() if "_label_" in raw_df.columns else raw_df[[url_col]].copy()
        df_temp["_label_"] = labels
        def get_tld(u):
            try:
                h = urlparse(u if "://" in u else f"http://{u}").hostname or ""
                return h.split(".")[-1] if "." in h else "unknown"
            except Exception:
                return "unknown"
        df_temp["tld"] = df_temp[url_col].fillna("").apply(get_tld)
        tld_ph = df_temp[df_temp["_label_"] == 1]["tld"].value_counts().head(8)
        tld_le = df_temp[df_temp["_label_"] == 0]["tld"].value_counts().head(8)
        for tld_val, cnt in tld_ph.items():
            tld_stats.setdefault(str(tld_val), {"tld": str(tld_val), "phishing": 0, "legitimate": 0})
            tld_stats[str(tld_val)]["phishing"] = int(cnt)
        for tld_val, cnt in tld_le.items():
            tld_stats.setdefault(str(tld_val), {"tld": str(tld_val), "phishing": 0, "legitimate": 0})
            tld_stats[str(tld_val)]["legitimate"] = int(cnt)
        tld_chart = sorted(tld_stats.values(), key=lambda x: x["phishing"] + x["legitimate"], reverse=True)[:10]
    else:
        tld_chart = []

    # 4. Feature stats (mean per class)
    feature_stats = []
    numeric_cols = raw_df.select_dtypes(include=[np.number]).columns.tolist()
    numeric_cols = [c for c in numeric_cols if c not in ("_label_", "id", "ID")]
    for col in numeric_cols[:15]:
        ph_mean = float(raw_df.loc[labels == 1, col].mean()) if (labels == 1).any() else 0
        le_mean = float(raw_df.loc[labels == 0, col].mean()) if (labels == 0).any() else 0
        feature_stats.append({"feature": col, "phishing_mean": round(ph_mean, 3), "legit_mean": round(le_mean, 3)})

    return {
        "label_distribution": label_dist,
        "url_length_histogram": url_lengths,
        "tld_distribution":    tld_chart,
        "feature_stats":       feature_stats,
        "dataset_info":        info,
    }
