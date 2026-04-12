"""世界层测试入口。"""

from test_ecosystem import WORLD_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("world", WORLD_TESTS)
