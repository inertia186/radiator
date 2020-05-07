module Radiator
  module ChainConfig
    EXPIRE_IN_SECS = 600
    EXPIRE_IN_SECS_PROPOSAL = 24 * 60 * 60

    NETWORKS_STEEM_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_STEEM_ADDRESS_PREFIX = 'STM'
    NETWORKS_STEEM_CORE_ASSET = ["0", 3, "@@000000021"] # STEEM
    NETWORKS_STEEM_DEBT_ASSET = ["0", 3, "@@000000013"] # SBD
    NETWORKS_STEEM_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_STEEM_CORE_SYMBOL = 'STEEM'
    NETWORKS_STEEM_DEBT_SYMBOL = 'SBD'
    NETWORKS_STEEM_VEST_SYMBOL = 'VESTS'
    NETWORKS_STEEM_DEFAULT_NODE = 'https://api.steemit.com' # √
    NETWORKS_STEEM_FAILOVER_URLS = [
       NETWORKS_STEEM_DEFAULT_NODE,
       'https://appbasetest.timcliff.com',
       'https://api.steem.house',
       'https://steemd.minnowsupportproject.org',
       'https://steemd.privex.io',
       'https://rpc.steemviz.com',
       'httpd://rpc.usesteem.com'
    ]
    NETWORKS_STEEM_RESTFUL_URL = 'https://anyx.io/v1'
    NETWORKS_STEEM_ENGINE_URL = 'https://api.steem-engine.com/rpc'

    NETWORKS_TEST_CHAIN_ID = '46d82ab7d8db682eb1959aed0ada039a6d49afa1602491f93dde9cac3e8e6c32'
    NETWORKS_TEST_ADDRESS_PREFIX = 'TST'
    NETWORKS_TEST_CORE_ASSET = ["0", 3, "@@000000021"] # TESTS
    NETWORKS_TEST_DEBT_ASSET = ["0", 3, "@@000000013"] # TBD
    NETWORKS_TEST_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_TEST_CORE_SYMBOL = 'TESTS'
    NETWORKS_TEST_DEBT_SYMBOL = 'TBD'
    NETWORKS_TEST_VEST_SYMBOL = 'VESTS'
    NETWORKS_TEST_DEFAULT_NODE = 'https://testnet.steemitdev.com'
    NETWORKS_TEST_FAILOVER_URLS = [
       NETWORKS_TEST_DEFAULT_NODE,
       "https://test.steem.ws"
    ]
    NETWORKS_TEST_RESTFUL_URL = ''
    NETWORKS_TEST_ENGINE_URL = ''

    NETWORKS_HIVE_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_HIVE_ADDRESS_PREFIX = 'STM'
    NETWORKS_HIVE_CORE_ASSET = ["0", 3, "@@000000021"] # HIVE
    NETWORKS_HIVE_DEBT_ASSET = ["0", 3, "@@000000013"] # HBD
    NETWORKS_HIVE_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_HIVE_CORE_SYMBOL = 'HIVE'
    NETWORKS_HIVE_DEBT_SYMBOL = 'HBD'
    NETWORKS_HIVE_VEST_SYMBOL = 'VESTS'
    NETWORKS_HIVE_DEFAULT_NODE = 'https://api.openhive.network' # √
    NETWORKS_HIVE_FAILOVER_URLS = [
       NETWORKS_HIVE_DEFAULT_NODE,
       'https://anyx.io',
       'https://api.hive.blog',
       'https://api.openhive.network',
       'https://api.hivekings.com'
    ]
    NETWORKS_HIVE_RESTFUL_URL = 'https://anyx.io/v1'
    NETWORKS_HIVE_ENGINE_URL = 'https://api.hive-engine.com/rpc'

    NETWORK_CHAIN_IDS = [
       NETWORKS_STEEM_CHAIN_ID,
       NETWORKS_TEST_CHAIN_ID,
       NETWORKS_HIVE_CHAIN_ID]
  end
end
