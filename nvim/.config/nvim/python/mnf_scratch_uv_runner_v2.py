from __future__ import annotations

import json
import os
import sys
import traceback
from argparse import ArgumentParser
from typing import Any

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)


class _State:
    target_filename: str | None = None
    current_line: int | None = None
    anchor: int = 1
    events: list[dict[str, Any]] | None = None


STATE = _State()


def _trace(frame, event, arg):  # noqa: ARG001
    if event == "line":
        if STATE.target_filename and frame.f_code.co_filename == STATE.target_filename:
            STATE.current_line = frame.f_lineno
    return _trace


def _stack_target_lineno() -> int | None:
    filename = STATE.target_filename
    if not filename:
        return None
    try:
        frame = sys._getframe()
    except Exception:
        return None

    while frame:
        if frame.f_code.co_filename == filename:
            return frame.f_lineno
        frame = frame.f_back
    return None


class _Stream:
    def __init__(self, stream: str):
        self.stream = stream
        self._buf = ""
        self._buf_line: int | None = None

    def write(self, s):
        if not s:
            return 0
        s = str(s)
        callsite = _stack_target_lineno() or STATE.anchor
        if not self._buf:
            self._buf_line = callsite
        self._buf += s
        while "\n" in self._buf:
            line, self._buf = self._buf.split("\n", 1)
            if STATE.events is not None:
                STATE.events.append(
                    {
                        "type": "out",
                        "line": self._buf_line or callsite,
                        "stream": self.stream,
                        "text": line,
                    }
                )
            self._buf_line = callsite if self._buf else None
        return len(s)

    def flush(self):
        if self._buf and STATE.events is not None:
            STATE.events.append(
                {
                    "type": "out",
                    "line": self._buf_line or _stack_target_lineno() or STATE.anchor,
                    "stream": self.stream,
                    "text": self._buf,
                }
            )
        self._buf = ""
        self._buf_line = None

    def isatty(self):
        return False


def _tb_line(exc: BaseException):
    tb = exc.__traceback__
    if not tb or not STATE.target_filename:
        return None
    frames = traceback.extract_tb(tb)
    for fr in reversed(frames):
        if fr.filename == STATE.target_filename:
            return fr.lineno
    return None


def _configure_matplotlib(*, cache_dir: str, filename: str, anchor: int) -> None:
    try:
        mplconf = os.path.join(cache_dir, "mnf", "matplotlib")
        os.makedirs(mplconf, exist_ok=True)
        os.environ.setdefault("MPLCONFIGDIR", mplconf)

        import matplotlib  # type: ignore

        try:
            matplotlib.use("module://mnf_scratch_mpl", force=True)
        except Exception:
            matplotlib.use("Agg", force=True)

        import mnf_scratch_mpl

        plot_dir = os.path.join(cache_dir, "mnf", "scratch", "plots")
        os.makedirs(plot_dir, exist_ok=True)
        mnf_scratch_mpl.configure(cache_dir=plot_dir, filename=filename, anchor=anchor)

        try:
            import matplotlib.pyplot as plt  # type: ignore

            plt.show = mnf_scratch_mpl.show
        except Exception:
            pass
    except Exception:
        return


def _run(code: str, filename: str, anchor: int, *, mpl: bool, cache_dir: str | None) -> list[dict[str, Any]]:
    env: dict[str, Any] = {"__name__": "__mnf_scratch__"}

    STATE.target_filename = filename
    STATE.current_line = 1
    STATE.anchor = anchor
    STATE.events = []

    if mpl and cache_dir:
        _configure_matplotlib(cache_dir=cache_dir, filename=filename, anchor=anchor)

    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = _Stream("stdout")
    sys.stderr = _Stream("stderr")
    sys.settrace(_trace)

    try:
        compiled = compile(code, filename, "exec")
        exec(compiled, env, env)  # noqa: S102
    except BaseException as e:
        line = _tb_line(e) or STATE.current_line or anchor
        trace = traceback.format_exception(type(e), e, e.__traceback__)
        trace = [t.rstrip("\n") for t in trace if t]
        STATE.events.append(
            {
                "type": "error",
                "line": line,
                "message": f"{type(e).__name__}: {e}",
                "trace": trace,
            }
        )
    finally:
        sys.settrace(None)
        try:
            sys.stdout.flush()
            sys.stderr.flush()
        except Exception:
            pass
        sys.stdout, sys.stderr = old_out, old_err

        if mpl and cache_dir:
            try:
                import mnf_scratch_mpl

                imgs = mnf_scratch_mpl.drain()
            except Exception:
                imgs = []
            for img in imgs or []:
                if isinstance(img, dict) and img.get("file"):
                    STATE.events.append(
                        {
                            "type": "image",
                            "line": int(img.get("line") or anchor),
                            "file": str(img["file"]),
                        }
                    )

        events = STATE.events or []
        STATE.events = None

    return events


def _bool(value: object, default: bool) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value != 0
    if isinstance(value, str):
        return value not in {"0", "false", "False", ""}
    return bool(value)


def _run_once() -> int:
    try:
        req = json.load(sys.stdin)
    except Exception as e:
        trace = traceback.format_exception(type(e), e, e.__traceback__)
        out = [{"type": "error", "line": 1, "message": f"uv runner: {e}", "trace": [t.rstrip("\n") for t in trace]}]
        print(json.dumps(out, ensure_ascii=False))
        return 2

    code = str((req or {}).get("code") or "")
    filename = str((req or {}).get("filename") or "<mnf-scratch-python>")
    anchor = int((req or {}).get("anchor") or 1)
    cache_dir = (req or {}).get("cache_dir")
    cache_dir = str(cache_dir) if isinstance(cache_dir, str) and cache_dir else None
    mpl = _bool((req or {}).get("mpl"), True) and _bool((req or {}).get("plots"), True)

    events = _run(code, filename, anchor, mpl=mpl, cache_dir=cache_dir)
    print(json.dumps(events, ensure_ascii=False))
    return 0


def _serve_jsonl() -> int:
    for raw in sys.stdin:
        raw = raw.strip("\n")
        if not raw.strip():
            continue

        try:
            req = json.loads(raw)
        except Exception as e:
            trace = traceback.format_exception(type(e), e, e.__traceback__)
            out = [
                {
                    "type": "error",
                    "line": 1,
                    "message": f"uv runner (server): {e}",
                    "trace": [t.rstrip("\n") for t in trace],
                }
            ]
            print(json.dumps(out, ensure_ascii=False), flush=True)
            continue

        try:
            code = str((req or {}).get("code") or "")
            filename = str((req or {}).get("filename") or "<mnf-scratch-python>")
            anchor = int((req or {}).get("anchor") or 1)
            cache_dir = (req or {}).get("cache_dir")
            cache_dir = str(cache_dir) if isinstance(cache_dir, str) and cache_dir else None
            mpl = _bool((req or {}).get("mpl"), True) and _bool((req or {}).get("plots"), True)

            events = _run(code, filename, anchor, mpl=mpl, cache_dir=cache_dir)
            print(json.dumps(events, ensure_ascii=False), flush=True)
        except Exception as e:
            trace = traceback.format_exception(type(e), e, e.__traceback__)
            out = [
                {
                    "type": "error",
                    "line": 1,
                    "message": f"uv runner (server): {e}",
                    "trace": [t.rstrip("\n") for t in trace],
                }
            ]
            print(json.dumps(out, ensure_ascii=False), flush=True)

    return 0


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    parser = ArgumentParser(add_help=True)
    parser.add_argument(
        "--server",
        action="store_true",
        help="Read JSONL requests from stdin, write one JSON response line per request.",
    )
    args = parser.parse_args(argv)
    if args.server:
        return _serve_jsonl()
    return _run_once()


if __name__ == "__main__":
    raise SystemExit(main())
