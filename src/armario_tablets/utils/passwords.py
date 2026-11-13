"""Salted, memory-hard password hashing; no plaintext credentials are retained."""

import hashlib
import hmac
import secrets

# OWASP's 16 MiB alternative: N=2^14, r=8, p=5. No extra dependency required.
_N, _R, _P = 16384, 8, 5


def hash_password(password: str) -> str:
    if not 12 <= len(password) <= 256:
        raise ValueError("A senha deve ter entre 12 e 256 caracteres.")
    salt = secrets.token_bytes(16)
    digest = hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=_N,
        r=_R,
        p=_P,
        maxmem=64 * 1024 * 1024,
        dklen=32,
    )
    return f"scrypt${_N}${_R}${_P}${salt.hex()}${digest.hex()}"


def verify_password(password: str, encoded: str) -> bool:
    try:
        algorithm, n, r, p, salt_hex, digest_hex = encoded.split("$")
        if algorithm != "scrypt" or (n, r, p) != (str(_N), str(_R), str(_P)):
            return False
        salt, expected = bytes.fromhex(salt_hex), bytes.fromhex(digest_hex)
        if len(salt) != 16 or len(expected) != 32 or len(password) > 256:
            return False
        actual = hashlib.scrypt(
            password.encode("utf-8"),
            salt=salt,
            n=_N,
            r=_R,
            p=_P,
            maxmem=64 * 1024 * 1024,
            dklen=32,
        )
        return hmac.compare_digest(actual, expected)
    except (ValueError, UnicodeError):
        return False


# A missing account performs the same KDF work as a real password check.
DUMMY_PASSWORD_HASH = hash_password(secrets.token_urlsafe(32))
