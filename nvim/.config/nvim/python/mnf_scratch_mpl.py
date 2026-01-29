"""MNF scratch Matplotlib backend (Agg-derived).

Goal: capture `plt.show()` / `fig.show()` in a *non-interactive* backend by
saving figures to PNG and letting Neovim render them (e.g. via Snacks.image).

This is implemented using Matplotlib's backend API (no monkeypatching of
`pyplot.show`). The runner configures it via `module://mnf_scratch_mpl`.

The module must remain importable even when Matplotlib isn't installed.
"""

from __future__ import annotations

import os
import sys
import tempfile
from typing import Any

_CACHE_DIR: str | None = None
_FILENAME: str | None = None
_ANCHOR: int = 1
_PENDING: list[dict[str, Any]] = []
_BACKEND_READY: bool = False
_BACKEND_ERROR: BaseException | None = None


def configure(*, cache_dir: str, filename: str, anchor: int) -> None:
    global _CACHE_DIR, _FILENAME, _ANCHOR, _PENDING
    _CACHE_DIR = cache_dir
    _FILENAME = filename
    _ANCHOR = int(anchor or 1)
    _PENDING = []


def drain() -> list[dict[str, Any]]:
    global _PENDING
    out = _PENDING
    _PENDING = []
    return out


def clear_figures() -> None:
    """
    Best-effort cleanup of pyplot-managed figures.

    The uv runner keeps a long-lived Python process for performance, so global
    Matplotlib state can otherwise leak across requests.
    """
    if "matplotlib" not in sys.modules:
        return
    try:
        from matplotlib import _pylab_helpers  # type: ignore

        _pylab_helpers.Gcf.destroy_all()
    except Exception:
        return


def _stack_target_lineno() -> int | None:
    filename = _FILENAME
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


def _guess_line() -> int:
    return _stack_target_lineno() or _ANCHOR


def _alloc_png_path(cache_dir: str) -> str:
    fd, path = tempfile.mkstemp(prefix="plot-", suffix=".png", dir=cache_dir)
    try:
        os.close(fd)
    except Exception:
        pass
    return path


def _save_figure_png(fig: Any, *, line: int) -> None:
    cache_dir = _CACHE_DIR
    if not cache_dir:
        return
    os.makedirs(cache_dir, exist_ok=True)
    path = _alloc_png_path(cache_dir)
    try:
        canvas = getattr(fig, "canvas", None)
        if canvas is not None:
            try:
                canvas.draw()
            except Exception:
                pass
        fig.savefig(path)
    except Exception:
        try:
            os.unlink(path)
        except Exception:
            pass
        return
    _PENDING.append({"file": path, "line": line})


def _ensure_backend() -> None:
    global _BACKEND_READY, _BACKEND_ERROR
    if _BACKEND_READY:
        return

    try:
        from matplotlib.backend_bases import FigureManagerBase, _Backend  # type: ignore
        from matplotlib.backends.backend_agg import FigureCanvasAgg  # type: ignore
        from matplotlib._pylab_helpers import Gcf  # type: ignore
    except Exception as e:  # pragma: no cover
        _BACKEND_ERROR = e
        _BACKEND_READY = True
        return

    class FigureManager(FigureManagerBase):  # type: ignore[misc]
        def show(self) -> None:  # noqa: D401
            """
            Save the figure to PNG and enqueue it for Neovim.

            When not configured, fall back to the default non-GUI behavior
            (emit a warning via NonGuiException).
            """
            if not _CACHE_DIR:
                return super().show()

            line = _guess_line()
            try:
                _save_figure_png(self.canvas.figure, line=line)  # type: ignore[attr-defined]
            finally:
                # Avoid re-emitting stale figures across requests in a persistent
                # runner process.
                try:
                    Gcf.destroy(self)
                except Exception:
                    pass

    class FigureCanvas(FigureCanvasAgg):  # type: ignore[misc]
        manager_class = FigureManager

    globals().update({"FigureCanvas": FigureCanvas, "FigureManager": FigureManager})

    class _BackendMnfScratch(_Backend):
        pass

    _BackendMnfScratch.backend_version = "0.1"
    _BackendMnfScratch.FigureCanvas = FigureCanvas
    _BackendMnfScratch.FigureManager = FigureManager
    _BackendMnfScratch.mainloop = None

    # Populate module-level names (FigureCanvas, show, ...).
    _Backend.export(_BackendMnfScratch)

    _BACKEND_READY = True


def __getattr__(name: str) -> Any:  # noqa: D401
    """
    Lazy backend initialization.

    The runner may import this module just to call `configure()` before
    Matplotlib is imported; in that case we don't want to import Matplotlib
    eagerly. When Matplotlib later loads the backend, attribute access will
    trigger `_ensure_backend()`.
    """
    if name in {
        "backend_version",
        "FigureCanvas",
        "FigureManager",
        "new_figure_manager",
        "new_figure_manager_given_figure",
        "draw_if_interactive",
        "show",
        "Show",
    }:
        _ensure_backend()
        if name in globals():
            return globals()[name]
        if _BACKEND_ERROR is not None:
            raise AttributeError(name) from _BACKEND_ERROR
        raise AttributeError(name)
    raise AttributeError(name)


def show(*args, **kwargs) -> None:  # noqa: D401
    """
    Called by `matplotlib.pyplot.show()`.
    Saves all current figures to PNG and records them for Neovim.

    Style policy: do not override user savefig/style settings here.
    """
    # `show` is normally provided by Matplotlib's backend export machinery.
    # This fallback keeps older Matplotlib versions usable, and also keeps this
    # module safe to import without Matplotlib installed.
    if not _CACHE_DIR:
        return
    try:
        from matplotlib import _pylab_helpers  # type: ignore
    except Exception:
        return
    managers = _pylab_helpers.Gcf.get_all_fig_managers()
    if not managers:
        return

    line = _guess_line()
    for m in list(managers):
        try:
            _save_figure_png(m.canvas.figure, line=line)
        except Exception:
            pass
        finally:
            try:
                _pylab_helpers.Gcf.destroy(m)
            except Exception:
                pass
