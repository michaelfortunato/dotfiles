## from kitty.boss import Boss
##
##
## def main(args: list[str]) -> str:
##     pass
##
##
## from kittens.tui.handler import result_handler
##
##
## @result_handler(no_ui=True)
## def handle_result(
##     args: list[str], answer: str, target_window_id: int, boss: Boss
## ) -> None:
##     tab = boss.active_tab
##     if tab is not None:
##         if tab.current_layout.name == "stack":
##             tab.last_used_layout()
##         else:
##             tab.goto_layout("stack")


from kitty.boss import Boss
from kittens.tui.handler import result_handler
import json
import time

# See here: https://github.com/kovidgoyal/kitty/issues/2119
# def main(args):
#     pass
#
# def handle_result(args, answer, target_window_id, boss):
#     tab = boss.active_tab
#     active_win = tab.active_window
#     win_count = len(tab.windows)
#     is_zoomed = tab.current_layout.name == 'stack'
#
#     nvim_win = None
#     cwd = None
#
#     for w in tab.windows:
#         p = w.child.foreground_processes[0]
#         if 'nvim' in p.get('cmdline'):
#             nvim_win = w
#             cwd = p.get('cwd')
#             break
#
#     if nvim_win is not None:
#         if active_win.id == nvim_win.id:
#             if win_count == 1:
#                 tab.goto_layout('fat:bias=70')
#                 tab.new_window(cwd=cwd)
#             else:
#                 if is_zoomed == True:
#                     neighbor_win = list(filter(lambda wd: wd.id != nvim_win.id, tab.windows))[0]
#                     tab.goto_layout('fat:bias=70')
#                     tab.set_active_window(neighbor_win)
#                 else:
#                     tab.goto_layout('stack')
#         elif win_count > 1 and active_win.id != nvim_win.id:
#             tab.set_active_window(nvim_win)
#             tab.goto_layout('stack')
#
# handle_result.no_ui = True


def main(args: list[str]) -> str:
    pass


def safe_call(func, *args, **kwargs):
    try:
        return func(*args, **kwargs)
    except Exception as e:
        print(f"Error calling {func.__name__}: {e}")
        return None  # Or a default value


def run_command_on_window_id(boss, tab, id, args):
    result = boss.call_remote_control(
        tab,
        ("send-text", f"--match=id:{id}", *args),
    )
    command_result = boss.call_remote_control(
        tab,
        ("send-key", f"--match=id:{id}", "enter"),
    )


def run_command(boss, args):
    # TODO: Add support for options

    tab = boss.active_tab
    try:
        match = boss.call_remote_control(tab, ("ls", "--match=var:neovim_runner"))
        match_obj = json.loads(match)
        print(match_obj)
        id = match_obj[0]["tabs"][0]["windows"][0]["id"]
        run_command_on_window_id(boss, tab, id, args[1:])
        # result = boss.call_remote_control(
        #     tab,
        #     ("send-text", f"--match=id:{id}", *args[1:]),
        # )
        # command_result = boss.call_remote_control(
        #     tab,
        #     ("send-key", f"--match=id:{id}", "enter"),
        # )
    except Exception as e:
        # _rc = boss.call_remote_control(
        #     tab,
        #     ("goto-layout", "Fat"),
        # )
        id = boss.call_remote_control(
            tab,
            (
                "launch",
                "--var=neovim_runner",
                "--keep-focus",
                "--cwd=current",
                "--location=hsplit",  # TODO: ensure stack layout and then run --location last to get hidden window
                "--bias=30",
            ),
        )
        # my shell is so slow I need to wait for it to catch up before running
        run_command_on_window_id(boss, tab, id, args[1:])


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    run_command(boss, args)
