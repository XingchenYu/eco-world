"""基础测试入口。"""

from test_ecosystem import BASIC_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("basic", BASIC_TESTS)
