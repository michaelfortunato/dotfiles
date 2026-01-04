"""MNF scratch Matplotlib backend (Agg-derived).

Used via `matplotlib.use("module://mnf_scratch_mpl")` so `plt.show()` saves PNGs
and Neovim renders them via Snacks.image.
"""

from __future__ import annotations

import os
import time
import traceback
from typing import Any

_CACHE_DIR: str | None = None
_FILENAME: str | None = None
_ANCHOR: int = 1
_PENDING: list[dict[str, Any]] = []


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


def _guess_line() -> int:
    if not _FILENAME:
        return _ANCHOR
    for fr in reversed(traceback.extract_stack()):
        if fr.filename == _FILENAME:
            return int(fr.lineno or _ANCHOR)
    return _ANCHOR


# Minimal backend surface: reuse Agg canvas/manager, override only `show()`.
try:
    from matplotlib.backends.backend_agg import (  # type: ignore
        FigureCanvasAgg as FigureCanvas,  # noqa: F401
        FigureManager,  # noqa: F401
        new_figure_manager,  # noqa: F401
        new_figure_manager_given_figure,  # noqa: F401
    )
except Exception:  # pragma: no cover
    FigureCanvas = None  # type: ignore
    FigureManager = None  # type: ignore
    new_figure_manager = None  # type: ignore
    new_figure_manager_given_figure = None  # type: ignore


def show(*args, **kwargs) -> None:  # noqa: D401
    """
    Called by `matplotlib.pyplot.show()`.
    Saves all current figures to PNG and records them for Neovim.

    Style policy: do not override user savefig/style settings here.
    """
    if not _CACHE_DIR:
        return
    try:
        from matplotlib import _pylab_helpers  # type: ignore
    except Exception:
        return
    managers = _pylab_helpers.Gcf.get_all_fig_managers()
    if not managers:
        return

    os.makedirs(_CACHE_DIR, exist_ok=True)
    line = _guess_line()
    for m in managers:
        try:
            fig = m.canvas.figure
            try:
                m.canvas.draw()
            except Exception:
                pass
            path = os.path.join(_CACHE_DIR, f"plot-{int(time.time_ns())}.png")
            # Keep defaults: don't pass dpi/bbox/facecolor/etc.
            fig.savefig(path)
            _PENDING.append({"file": path, "line": line})
        except Exception:
            continue
