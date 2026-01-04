import json
import os
import sys
import traceback

import vim

# Make `stdpath('config')/python` importable (where `mnf_scratch_mpl.py` lives).
try:
    _config = vim.eval("stdpath('config')")
    _python_dir = os.path.join(str(_config), "python")
    if _python_dir not in sys.path:
        sys.path.insert(0, _python_dir)
except Exception:
    pass

_SESSIONS = globals().get("_MNF_SCRATCH_PYTHON_SESSIONS")
if _SESSIONS is None:
    _SESSIONS = {}
    globals()["_MNF_SCRATCH_PYTHON_SESSIONS"] = _SESSIONS


class _State:
    target_filename = None
    current_line = None
    anchor = 1
    events = None


STATE = _State()


def _trace(frame, event, arg):
    if event == "line":
        if STATE.target_filename and frame.f_code.co_filename == STATE.target_filename:
            STATE.current_line = frame.f_lineno
    return _trace


class _Stream:
    def __init__(self, stream: str):
        self.stream = stream
        self._buf = ""

    def write(self, s):
        if not s:
            return 0
        self._buf += str(s)
        while "\n" in self._buf:
            line, self._buf = self._buf.split("\n", 1)
            if STATE.events is not None:
                STATE.events.append(
                    {
                        "type": "out",
                        "line": STATE.current_line or STATE.anchor,
                        "stream": self.stream,
                        "text": line,
                    }
                )
        return len(s)

    def flush(self):
        if self._buf and STATE.events is not None:
            STATE.events.append(
                {
                    "type": "out",
                    "line": STATE.current_line or STATE.anchor,
                    "stream": self.stream,
                    "text": self._buf,
                }
            )
        self._buf = ""

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


def _get_session(buf: int):
    env = _SESSIONS.get(buf)
    if env is None:
        env = {"__name__": "__mnf_scratch__"}
        _SESSIONS[buf] = env
    return env


def _mpl_enabled() -> bool:
    try:
        return int(vim.vars.get("mnf_scratch_python_mpl", 1)) == 1
    except Exception:
        return True


def _configure_python_path():
    # Ensure `stdpath('config')/python` is importable so we can load helper modules.
    try:
        config = vim.eval("stdpath('config')")
        python_dir = os.path.join(str(config), "python")
        if python_dir not in sys.path:
            sys.path.insert(0, python_dir)
    except Exception:
        pass


def _configure_matplotlib(*, filename: str, anchor: int) -> None:
    try:
        # Certified path: select a Matplotlib backend module (Agg-derived) so that
        # `pyplot.show()` dispatches to our `mnf_scratch_mpl.show`.
        cache = vim.eval("stdpath('cache')")
        mplconf = os.path.join(str(cache), "mnf", "matplotlib")
        os.makedirs(mplconf, exist_ok=True)
        os.environ.setdefault("MPLCONFIGDIR", mplconf)

        import matplotlib

        try:
            matplotlib.use("module://mnf_scratch_mpl", force=True)
        except Exception:
            matplotlib.use("Agg", force=True)

        import mnf_scratch_mpl

        plot_dir = os.path.join(str(cache), "mnf", "scratch", "plots")
        os.makedirs(plot_dir, exist_ok=True)
        mnf_scratch_mpl.configure(cache_dir=plot_dir, filename=filename, anchor=anchor)

        # Fallback: if pyplot is already imported, ensure show is ours anyway.
        try:
            import matplotlib.pyplot as plt

            if getattr(plt.show, "__module__", "") != "mnf_scratch_mpl":
                plt.show = mnf_scratch_mpl.show
        except Exception:
            pass
    except Exception:
        return


def _run(buf: int, code: str, filename: str, anchor: int):
    env = _get_session(buf)

    STATE.target_filename = filename
    STATE.current_line = 1
    STATE.anchor = anchor
    STATE.events = []

    mpl = _mpl_enabled()
    if mpl:
        # Optional matplotlib support:
        # - `plt.show()` -> save PNG -> emit `{"type":"image","file":...,"line":...}`.
        _configure_python_path()
        _configure_matplotlib(filename=filename, anchor=anchor)

    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = _Stream("stdout")
    sys.stderr = _Stream("stderr")
    sys.settrace(_trace)

    try:
        compiled = compile(code, filename, "exec")
        exec(compiled, env, env)
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
        if mpl:
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
        events = STATE.events
        STATE.events = None

    return events


def _mnf_scratch_python_run_from_vim():
    buf = int(vim.vars.get("mnf_scratch_python__buf") or 0)
    anchor = int(vim.vars.get("mnf_scratch_python__anchor") or 1)
    filename = str(vim.vars.get("mnf_scratch_python__filename") or "<mnf-scratch-python>")
    code = str(vim.vars.get("mnf_scratch_python__code") or "")

    events = _run(buf, code, filename, anchor)
    vim.vars["mnf_scratch_python__last"] = json.dumps(events, ensure_ascii=False)


def _mnf_scratch_python_reset_from_vim():
    buf = int(vim.vars.get("mnf_scratch_python__buf") or 0)
    _SESSIONS[buf] = {"__name__": "__mnf_scratch__"}


vim.vars["mnf_scratch_python_provider_ready"] = 1
