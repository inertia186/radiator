module Radiator
  module ChainConfig
    EXPIRE_IN_SECS = 600
    EXPIRE_IN_SECS_PROPOSAL = 24 * 60 * 60
    
    NETWORKS_STEEM_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_STEEM_ADDRESS_PREFIX = 'STM'
    NETWORKS_STEEM_CORE_ASSET = 'STEEM'
    NETWORKS_STEEM_DEBT_ASSET = 'SBD'
    NETWORKS_STEEM_VEST_ASSET = 'VESTS'
    NETWORKS_STEEM_NETWORKS_NODE = 'https://api.steemit.com'
    NETWORKS_STEEM_RESTFUL_URL = 'https://anyx.io/v1'
    NETWORKS_STEEM_FAILOVER_URLS = [
       NETWORKS_STEEM_NETWORKS_NODE,
       'https://appbasetest.timcliff.com',
       'https://api.steem.house',
       'https://steemd.minnowsupportproject.org',
       'https://steemd.privex.io',
       'https://rpc.steemviz.com',
       'httpd://rpc.usesteem.com'
    ]

    NETWORKS_TEST_CHAIN_ID = '18dcf0a285365fc58b71f18b3d3fec954aa0c141c44e4e5cb4cf777b9eab274e'
    NETWORKS_TEST_ADDRESS_PREFIX = 'TST'
    NETWORKS_TEST_CORE_ASSET = 'CORE'
    NETWORKS_TEST_DEBT_ASSET = 'TEST'
    NETWORKS_TEST_VEST_ASSET = 'CESTS'
    NETWORKS_TEST_NETWORKS_NODE = 'https://test.steem.ws'
    NETWORKS_TEST_RESTFUL_URL = ''
    NETWORKS_TEST_FAILOVER_URLS = [
       NETWORKS_TEST_NETWORKS_NODE
    ]

    NETWORKS_HIVE_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_HIVE_ADDRESS_PREFIX = 'STM'
    NETWORKS_HIVE_CORE_ASSET = ["0", 3, "@@000000021"] # HIVE
    NETWORKS_HIVE_DEBT_ASSET = ["0", 3, "@@000000013"] # HBD
    NETWORKS_HIVE_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_HIVE_NETWORKS_NODE = 'https://api.openhive.network'
    NETWORKS_HIVE_RESTFUL_URL = 'https://anyx.io/v1'
    NETWORKS_HIVE_FAILOVER_URLS = [
       NETWORKS_HIVE_NETWORKS_NODE,
       'https://anyx.io',
       'https://api.hive.blog',
       'https://api.openhive.network',
       'https://api.hivekings.com'
    ]

    NETWORK_CHAIN_IDS = [
       NETWORKS_STEEM_CHAIN_ID,
       NETWORKS_TEST_CHAIN_ID,
       NETWORKS_HIVE_CHAIN_ID]
  end
end