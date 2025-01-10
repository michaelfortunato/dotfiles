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


def main(args: list[str]) -> str:
    pass


def toggle_term(boss):
    tab = boss.active_tab

    all_another_wins = tab.all_window_ids_except_active_window
    have_only_one = len(all_another_wins) == 0

    if have_only_one:
        boss.launch("--cwd=current", "--location=vsplit")
        tab.neighboring_window("right")
    else:
        if tab.current_layout.name == "stack":
            tab.last_used_layout()
            tab.neighboring_window("right")
        else:
            tab.neighboring_window("left")
            tab.goto_layout("stack")


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    window = boss.window_id_map.get(target_window_id)

    if window is None:
        return

    toggle_term(boss)
