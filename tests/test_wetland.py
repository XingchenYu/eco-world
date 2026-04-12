"""湿地链测试入口。"""

from test_ecosystem import WETLAND_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("wetland", WETLAND_TESTS)
