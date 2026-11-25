from kittens.tui.handler import result_handler
from kitty.fast_data_types import get_options


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    minimum = 1 if get_options().tab_bar_min_tabs == 999 else 999
    boss.call_remote_control(
        None, ("load-config", "--override", f"tab_bar_min_tabs={minimum}")
    )
