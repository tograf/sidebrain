#!/usr/bin/env python3
"""Launch whisper-ctranslate2 with the pip nvidia-* CUDA libs on the linker path.

CTranslate2 (faster-whisper's backend) dlopen()s libcublas.so.12 / libcudnn but
does NOT look inside site-packages/nvidia/*/lib, so the GPU path fails with
"Library libcublas.so.12 is not found" even when the nvidia-cublas-cu12 /
nvidia-cudnn-cu12 wheels are installed. We resolve those lib dirs, prepend them
to LD_LIBRARY_PATH, then exec the real CLI so the loader picks them up.

Used by yt-fetch.sh for the GPU branch only (CPU needs no CUDA libs). All args
are forwarded verbatim to whisper-ctranslate2.
"""
import importlib
import os
import sys


def libdir(module):
    m = importlib.import_module(module)
    # newer nvidia-* wheels ship these as namespace packages, so __file__ is None;
    # __path__ points straight at the dir holding the .so files.
    f = getattr(m, "__file__", None)
    if f:
        return os.path.dirname(f)
    paths = list(getattr(m, "__path__", []) or [])
    if not paths:
        raise ImportError(f"no path for {module}")
    return paths[0]


try:
    extra = os.pathsep.join(libdir(m) for m in ("nvidia.cublas.lib", "nvidia.cudnn.lib"))
    os.environ["LD_LIBRARY_PATH"] = extra + os.pathsep + os.environ.get("LD_LIBRARY_PATH", "")
except Exception as e:  # noqa: BLE001 - fall through; whisper will error and yt-fetch falls back to CPU
    print(f"whisper_gpu: could not locate CUDA libs ({e})", file=sys.stderr)

os.execvp("whisper-ctranslate2", ["whisper-ctranslate2", *sys.argv[1:]])
