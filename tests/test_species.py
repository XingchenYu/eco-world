"""关键物种测试入口。"""

from test_ecosystem import SPECIES_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("species", SPECIES_TESTS)
