"""草原链测试入口。"""

from test_ecosystem import GRASSLAND_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("grassland", GRASSLAND_TESTS)
