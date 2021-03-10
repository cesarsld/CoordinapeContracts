import pytest


@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass


@pytest.fixture()
def minter(accounts):
    return accounts[0]
    # return accounts.at("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", force=True)

@pytest.fixture()
def big(accounts):
    return accounts.at("0x742d35cc6634c0532925a3b844bc454e4438f44e", force=True)
