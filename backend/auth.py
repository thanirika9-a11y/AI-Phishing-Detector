import hashlib
import os

def hash_password(password: str) -> str:
    # Generate a random 16-byte salt
    salt = os.urandom(16)
    # Combine salt and password
    db_val = salt + password.encode('utf-8')
    # Hash using SHA-256
    hashed = hashlib.sha256(db_val).hexdigest()
    # Store salt and hash together split by a colon
    return f"{salt.hex()}:{hashed}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        salt_hex, hash_val = hashed_password.split(":")
        salt = bytes.fromhex(salt_hex)
        db_val = salt + plain_password.encode('utf-8')
        check_hash = hashlib.sha256(db_val).hexdigest()
        return check_hash == hash_val
    except Exception:
        return False
