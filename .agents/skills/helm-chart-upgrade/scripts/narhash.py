#!/usr/bin/env python3
"""Print the sha256 transpire.fetchFromHelm expects for an unpacked chart directory.

fetchFromHelm is a recursive (NAR) output hash of the chart dir, so no need to
push a wrong hash and read the right one out of a CI failure:

    curl -sO https://charts.rook.io/release/rook-ceph-v1.20.9.tgz
    mkdir c && tar xzf rook-ceph-v1.20.9.tgz -C c
    python3 narhash.py c/rook-ceph
"""
import base64, hashlib, os, struct, sys


def s(b):
    if isinstance(b, str):
        b = b.encode()
    return struct.pack("<Q", len(b)) + b + b"\0" * ((8 - len(b) % 8) % 8)


def nar(p):
    out = [s("(")]
    if os.path.islink(p):
        out += [s("type"), s("symlink"), s("target"), s(os.readlink(p))]
    elif os.path.isdir(p):
        out += [s("type"), s("directory")]
        for e in sorted(os.listdir(p)):
            out += [s("entry"), s("("), s("name"), s(e), s("node"), nar(os.path.join(p, e)), s(")")]
    else:
        out += [s("type"), s("regular")]
        if os.access(p, os.X_OK):
            out += [s("executable"), s("")]
        with open(p, "rb") as f:
            out += [s("contents"), s(f.read())]
    out.append(s(")"))
    return b"".join(out)


print(base64.b64encode(hashlib.sha256(s("nix-archive-1") + nar(sys.argv[1])).digest()).decode())
