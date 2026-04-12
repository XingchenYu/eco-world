"""运行期测试入口。"""

from test_ecosystem import RUNTIME_TESTS, _run_test_group


if __name__ == "__main__":
    _run_test_group("runtime", RUNTIME_TESTS)
