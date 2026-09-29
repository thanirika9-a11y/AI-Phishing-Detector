"""
Generate a realistic phishing URL dataset for training ML models.
This script creates a CSV with 500 URLs (300 phishing + 200 legitimate).
"""
import csv
import random
import string
import os

random.seed(42)

# ── Legitimate domains ──
LEGIT_DOMAINS = [
    "google.com", "github.com", "microsoft.com", "amazon.com", "linkedin.com",
    "stackoverflow.com", "wikipedia.org", "apple.com", "youtube.com", "facebook.com",
    "instagram.com", "twitter.com", "reddit.com", "netflix.com", "medium.com",
    "dropbox.com", "slack.com", "zoom.us", "adobe.com", "oracle.com",
    "salesforce.com", "shopify.com", "wordpress.com", "figma.com", "notion.so",
    "atlassian.com", "bitbucket.org", "cloudflare.com", "digitalocean.com", "heroku.com",
    "vercel.com", "npmjs.com", "pypi.org", "docker.com", "kubernetes.io",
    "tensorflow.org", "pytorch.org", "scipy.org", "pandas.pydata.org", "numpy.org"
]

LEGIT_PATHS = [
    "/about", "/contact", "/help", "/support", "/docs", "/pricing",
    "/features", "/blog", "/careers", "/login", "/signup", "/dashboard",
    "/settings", "/profile", "/products", "/services", "/download",
    "/terms", "/privacy", "/faq", "/status", "/api", "/community",
    "/enterprise", "/education", "/security", "/partners"
]

# ── Phishing patterns ──
PHISH_TLDS = ["xyz", "club", "top", "work", "cc", "tk", "ml", "gq", "cf", "click", "link", "bid", "stream"]
PHISH_BRANDS = ["paypal", "netflix", "chase", "amazon", "google", "apple", "microsoft", "facebook", "instagram", "wellsfargo", "bankofamerica", "citibank"]
PHISH_WORDS = [
    "secure-login", "verify-account", "billing-update", "account-suspend",
    "confirm-identity", "renew-subscription", "password-reset", "unlock-account",
    "security-alert", "update-payment", "claim-reward", "free-gift",
    "limited-offer", "urgent-action", "validate-info", "reactivate-now"
]
PHISH_SEPARATORS = ["-", ".", "_", ""]

def random_string(length=6):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def generate_phishing_url():
    """Generate a realistic-looking phishing URL."""
    brand = random.choice(PHISH_BRANDS)
    word = random.choice(PHISH_WORDS)
    tld = random.choice(PHISH_TLDS)
    sep = random.choice(PHISH_SEPARATORS)
    rand = random_string(random.randint(4, 8))

    patterns = [
        # Pattern 1: brand-phishword-random.tld/login
        f"http://{brand}{sep}{word}{sep}{rand}.{tld}/login?verify=1&token={random_string(12)}",
        # Pattern 2: brand.phishword.random.tld
        f"http://{brand}.{word}.{rand}.{tld}/account/verify",
        # Pattern 3: IP-based URL
        f"http://{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}/{brand}/login.php",
        # Pattern 4: long subdomain chain
        f"http://{brand}.{word}.{rand}.{random_string(4)}.{tld}/signin",
        # Pattern 5: brand misspelling
        f"http://{brand[:3]}{random_string(2)}{brand[3:]}.{tld}/{word}",
        # Pattern 6: @ trick
        f"http://{brand}.com@{rand}.{tld}/verify",
        # Pattern 7: numeric heavy
        f"http://{random_string(3)}{random.randint(100,999)}.{tld}/{brand}-{word}?id={random.randint(10000,99999)}",
        # Pattern 8: suspicious path
        f"http://{rand}-{brand}.{tld}/wp-admin/includes/login.php?redirect={brand}.com",
    ]
    return random.choice(patterns)

def generate_legit_url():
    """Generate a realistic legitimate URL."""
    domain = random.choice(LEGIT_DOMAINS)
    path = random.choice(LEGIT_PATHS)
    rand_path = random_string(random.randint(3, 8))

    patterns = [
        f"https://www.{domain}{path}",
        f"https://{domain}/{rand_path}",
        f"https://www.{domain}{path}/{rand_path}",
        f"https://{domain}/en{path}",
        f"https://docs.{domain}/{rand_path}",
        f"https://help.{domain}{path}",
    ]
    return random.choice(patterns)

def main():
    rows = []

    # Generate 300 phishing URLs
    for _ in range(300):
        rows.append({"url": generate_phishing_url(), "label": 1})

    # Generate 200 legitimate URLs
    for _ in range(200):
        rows.append({"url": generate_legit_url(), "label": 0})

    random.shuffle(rows)

    output_path = os.path.join(os.path.dirname(__file__), "datasets", "phishing_urls_dataset.csv")
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["url", "label"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"✅ Dataset created: {output_path}")
    print(f"   Total URLs: {len(rows)}")
    print(f"   Phishing:   {sum(1 for r in rows if r['label'] == 1)}")
    print(f"   Legitimate: {sum(1 for r in rows if r['label'] == 0)}")

if __name__ == "__main__":
    main()
