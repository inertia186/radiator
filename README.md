[![Build Status](https://travis-ci.org/inertia186/radiator.svg?branch=master)](https://travis-ci.org/inertia186/radiator)
[![Code Climate](https://codeclimate.com/github/inertia186/radiator/badges/gpa.svg)](https://codeclimate.com/github/inertia186/radiator)
[![Test Coverage](https://codeclimate.com/github/inertia186/radiator/badges/coverage.svg)](https://codeclimate.com/github/inertia186/radiator)
[![Inline docs](http://inch-ci.org/github/inertia186/radiator.svg?branch=master&style=shields)](http://inch-ci.org/github/inertia186/radiator)

[radiator](https://github.com/inertia186/radiator)
========

#### STEEM Ruby API Client

Radiator is an API Client for interaction with the STEEM network using Ruby.

#### Changes in v0.4.0

* Gem updates
* **AppBase Support**
  * Defaulting to `condenser_api.*` in `Radiator::Api` (see below)
  * Handle/recover from new `AppBase` errors.
* `Radiator::Stream` now detects if it's stalled and takes action if it has to wait too long for a new block.
  1. Exponential back-off for stalls so that the node doesn't get slammed.
  2. Short delays (3 times block production) only result in a warning.
  3. Long delays (6 times block production) may try to switch to an alternate node.
* Fixed internal logging bug that would open too many files.
  * This fix also mitigates issues like `SSL Verify` problems (similar to [#12](https://github.com/inertia186/radiator/issues/12))
* Dropped GOLOS support.

**Appbase is now supported.**

If you were already using `Radiator::Api` then there is nothing to change.  But if you made use of other API classes, like `Radiator::FollowApi`, then the method signatures have changed.

**Pre-AppBase:**

```ruby
api = Radiator::FollowApi.new

api.get_followers('inertia', 0, 'blog', 10)
```

**New Signature:**

```ruby
api = Radiator::FollowApi.new

api.get_followers(account: 'inertia', start: 0, type: 'blog', limit: 10)
```

*-- or --*

**Switch to Condenser API:**

The other strategy for using this version of Radiator is to just switch away from classes like `Radiator::FollowApi` over to `Radiator::Api` (also known as `Radiator::CondenserApi`) instead.  Then you don't have to update individual method calls.

```ruby
api = Radiator::Api.new

api.get_followers('inertia', 0, 'blog', 10)
```

**Note about GOLOS**

GOLOS is no longer supported in Radiator.  If you want to continue to use GOLOS, you'll need to branch from v0.3.15 (pre-appbase) and add WebSockets support because GOLOS completely dropped JSON-RPC over HTTP clients support for some reason 

Radiator has never and will never use WebSockets due to its server scalability requirements.

From a client perspective, WebSockets is *great*.  **I have nothing against WebSockets.**  So I might get around to it at some point, but GOLOS won't be part of Radiator anymore mainly because GOLOS has no plans to implement AppBase.

#### Changes in v0.3.0

* Gem updates
* Added failover subroutines (see Failover section, below).
* Added method closures support (aka passing a block to yield).
* You can now stream virtual operations (see Streaming section, below).
* Added more [documentation](http://www.rubydoc.info/gems/radiator).
* Added/expanded more api namespaces: `::BlockApi`, `::CondenserApi`, `::TagApi`
* Addressed an issue with logging on certain Windows configurations.

#### Fixes in v0.2.3

* Gem updates
* Added low-level support for persistence and retrying API requests.
* Now using exponential back-off for retries.
* Detecting presence of `transaction_ids` (if enabled by the node).
* Default for `Hashie` warnings now go to `/dev/null`, where they belong.
* Added stray methods/operations.

#### Fixes in v0.2.2

* Gem updates
* Improved support for datatypes and handlers.
  * UTF-8 handled more smoothly.
  * Simplified operation construction.
* Improved keep-alive defaults.
  * Better streaming reliability.

---

Also see: [Documentation](http://www.rubydoc.info/gems/radiator)

---

### Quick Start

Add the gem to your Gemfile:

```ruby
gem 'radiator'
```

Then:

```bash
$ bundle install
```

If you don't have `bundler`, see the next section.
    
### Prerequisites

`minimum ruby version: 2.2`

#### Linux

```bash
$ sudo apt-get install ruby-full git openssl libssl1.0.0 libssl-dev
$ gem install bundler
```

#### macOS

```
$ gem install bundler
```

### Usage

```ruby
require 'radiator'

api = Radiator::Api.new
api.get_dynamic_global_properties do |properties|
  properties.virtual_supply
end
=> "271342874.337 STEEM"
```

... or ...

```ruby
require 'radiator'

api = Radiator::Api.new
response = api.get_dynamic_global_properties
response.result.virtual_supply
=> "271342874.337 STEEM"
```

#### Follower API

```ruby
api = Radiator::FollowApi.new
api.get_followers(account: 'inertia', start: 0, type: 'blog', limit: 100) do |followers|
  followers.map(&:follower)
end
=> ["a11at",
 "abarefootpoet",
 "abit",
 "alexgr",
 "alexoz",
 "andressilvera",
 "applecrisp",
 "arrowj",
 "artificial",
 "ash",
 "ausbitbank",
 "beachbum",
 "ben99",
 "benadapt",
 .
 .
 .
 "steemzine"]
```

#### Streaming

Here's an example of how to use a streaming instance to listen for votes:

```ruby
require 'radiator'

stream = Radiator::Stream.new

stream.operations(:vote) do |op|
  print "#{op.voter} voted for #{op.author}"
  puts " (weight: #{op.weight / 100.0}%)"
end
```

The output would look like this and continue until interrupted.

```
richman voted for krnel (weight: 100.0%)
rainchen voted for rainchen (weight: 100.0%)
richman voted for exploretraveler (weight: 100.0%)
jlufer voted for michaelstobiersk (weight: 100.0%)
jlufer voted for michaelstobiersk (weight: 100.0%)
patelincho voted for borishaifa (weight: 100.0%)
richman voted for vetvso (weight: 100.0%)
jlufer voted for michaelstobiersk (weight: 100.0%)
richman voted for orcish (weight: 100.0%)
demotruk voted for skeptic (weight: -100.0%)
photorealistic voted for oecp85 (weight: 100.0%)
meesterboom voted for rubenalexander (weight: 100.0%)
thecurator voted for robyneggs (weight: 40.0%)
richman voted for originate (weight: 100.0%)
helikopterben voted for etcmike (weight: 100.0%)
.
.
.
```

You can also just stream all operations like this:

```ruby
stream.operations do |op|
  puts op.to_json
end
```

Example of the output:

```json
{
   "vote":{
      "voter":"abudar",
      "author":"rangkangandroid",
      "permlink":"the-kalinga-tattoo-maker",
      "weight":10000
   }
}
{
   "vote":{
      "voter":"shenburen",
      "author":"masteryoda",
      "permlink":"daily-payouts-leaderboards-september-16",
      "weight":10000
   }
}
{
   "vote":{
      "voter":"stiletto",
      "author":"fyrstikken",
      "permlink":"everybody-hating-me",
      "weight":2500
   }
}
{
   "comment":{
      "parent_author":"mariandavp",
      "parent_permlink":"re-onceuponatime-re-mariandavp-the-bridge-original-artwork-by-mariandavp-20160906t182016608z",
      "author":"onceuponatime",
      "permlink":"re-mariandavp-re-onceuponatime-re-mariandavp-the-bridge-original-artwork-by-mariandavp-20160917t054726763z",
      "title":"",
      "body":"https://www.steemimg.com/images/2016/09/17/oldcomputerpics551cb14c.jpg",
      "json_metadata":"{\"tags\":[\"art\"],\"image\":[\"https://www.steemimg.com/images/2016/09/17/oldcomputerpics551cb14c.jpg\"]}"
   }
}
{
   "vote":{
      "voter":"abudar",
      "author":"rangkangandroid",
      "permlink":"the-journey-north-through-the-eyes-of-kalinga-tradition",
      "weight":10000
   }
}
{
   "limit_order_cancel":{
      "owner":"fnait",
      "orderid":2755220300
   }
}
.
.
.
```

You can also stream virtual operations:

```ruby
stream.operations(:producer_reward) do |op|
  puts "#{op.producer} got a reward: #{op.vesting_shares}"
end
```

Example of the output:

```
anyx got a reward: 390.974648 VESTS
gtg got a reward: 390.974647 VESTS
someguy123 got a reward: 390.974646 VESTS
jesta got a reward: 390.974646 VESTS
blocktrades got a reward: 390.974645 VESTS
timcliff got a reward: 390.974644 VESTS
bhuz got a reward: 1961.046504 VESTS
.
.
.
```

Transactions are supported:

```ruby
stream.transactions do |tx, trx_id|
  puts "[#{trx_id}] #{tx.to_json}"
end
```

Example of the output:

```json
{
   "ref_block_num":59860,
   "ref_block_prefix":2619183808,
   "expiration":"2016-09-17T06:03:21",
   "operations":[
      [
         "custom_json",
         {
            "required_auths":[

            ],
            "required_posting_auths":[
               "acidpanda"
            ],
            "id":"follow",
            "json":"[\"follow\",{\"follower\":\"acidpanda\",\"following\":\"gavvet\",\"what\":[\"blog\"]}]"
         }
      ]
   ],
   "extensions":[],
   "signatures":[
      "2048d7e32cc843adea0e11aa617dc9cdc773d0e9a0a0d0cd58d67a9fcd8fa2d2305d1bb611ac219fbd3b6a77ab60071df94fe193aae33591ee669cc7404d4e4ec4"
   ]
}
.
.
.
```

Even whole blocks:

```ruby
stream.blocks do |bk, num|
  puts "[#{num}] #{bk.to_json}"
end
```

Example of the output:

```json
{
   "previous":"004cea0d46a4b91cffe7bb71763ad2ab854c6efd",
   "timestamp":"2016-09-17T06:05:51",
   "witness":"boatymcboatface",
   "transaction_merkle_root":"0000000000000000000000000000000000000000",
   "extensions":[],
   "witness_signature":"2034b0d7398ed1c0d7511ac76c6dedaf227e609dc2676d13f926ddd1e9df7fa9cb254af122a4a82dc619a1091c87293cbd9e2db1b51404fdc8fb62f8e5f37b4625",
   "transactions":[]
}
.
.
.
```

#### Transaction Signing

Radiator supports transaction signing, so you can use it to vote:

```ruby
tx = Radiator::Transaction.new(wif: 'Your Wif Here')
vote = {
  type: :vote,
  voter: 'xeroc',
  author: 'xeroc',
  permlink: 'piston',
  weight: 10000
}

tx.operations << vote
tx.process(true)
```

You can also post/comment:

```ruby
tx = Radiator::Transaction.new(wif: 'Your Wif Here')
comment = {
  type: :comment,
  parent_permlink: 'test',
  author: 'your-account',
  permlink: 'something-unique',
  title: 'Radiator Can Post Comments!',
  body: 'Yep, this post was created by Radiator in `ruby`.',
  json_metadata: '',
  parent_author: ''
}

tx.operations << comment
tx.process(true)
```

Transfers:

```ruby
tx = Radiator::Transaction.new(wif: 'Your Wif Here')
transfer = {
  type: :transfer,
  from: 'ned',
  to: 'inertia',
  amount: '100000.000 SBD',
  memo: 'Wow, inertia!  Radiator is great!'
}

tx.operations << transfer
tx.process(true)
```

There's a complete list of operations known to Radiator in [`broadcast_operations.json`](https://github.com/inertia186/radiator/blob/master/lib/radiator/broadcast_operations.json).

## Failover

Radiator supports failover for situations where a node has, for example, become unresponsive.  When creating a new instance of `::Api`, `::Stream`, and `::Transaction`, you may provide a list of alternative nodes, or leave them out to use the default list.  For example:

```ruby
options = {
  url: 'https://api.steemit.com',
  failover_urls: [
    'https://api.steemitstage.com',
    'https://api.steem.house'
  ]
}

api = Radiator::Api.new(options)
```

In a nutshell, the way this works is Radiator will try a node and proceed until it encounters an error, then retry the request.  If it encounters a second error within 5 minutes, it will abandon the node and try a random one from `failover_urls`.

It'll keep doing this until it runs out of failovers, then it will reset the configuration and go back to the original node.

Radiator uses an exponential back-off subroutine to avoid slamming nodes when they act up.

There's an additional behavior in `::Stream`.  When a node responds with a block out of sequence, it will use the failover logic above.  Although this is not a network layer failure, it is a bad result that may indicate a problem on the node, so a new node is picked.

There is another rare scenario involving `::Transaction` broadcasts that's handled by the failover logic: When a node responds with a network error *after* a signed transaction is accepted, Radiator will do a look-up to find the accepted signature in order to avoid triggering a `dupe_check` error from the blockchain.  This subroutine might take up to five minutes to execute in the worst possible situation.  To disable this behavior, use the `recover_transactions_on_error` and set it to `false`, e.g.:

```ruby
tx = Radiator::Transaction.new(wif: wif, recover_transactions_on_error: false)
```

## Debugging

To enable debugging, set environment `LOG=DEBUG` before launching your app.  E.g.:

```bash
$ LOG=DEBUG irb -rradiator
```

This will enable debugging for the `irb` session.

## Troubleshooting

## Problem: My log is full of `Unable to perform request ... retrying ...` messages.

```
W, [2017-10-10T11:38:30.035318 #6743]  WARN -- : database_api.get_dynamic_global_properties :: Unable to perform request: too many connection resets (due to Net::ReadTimeout - Net::ReadTimeout) after 0 requests on 26665356, last used 1507660710.035165 seconds ago :: cause: Net::ReadTimeout, retrying ...
```

This is caused by network interruptions.  If these messages happen once in a while, they can be ignored.  Radiator will retry the request and move on.  If there are more frequent warnings, this will trigger the failover logic and pick a new node, if one has been configured (which is true by default).  See the Failover section above.

## Problem: My log is full of `Invalid block sequence` messages.

```
W, [2017-10-10T13:53:24.327177 #6938]  WARN -- : Invalid block sequence at height: 16217674
```

This is a similar situation to `Unable to perform request ... retrying ...`.  Radiator::Stream will retry and failover if needed.  It is happening because the node has responded with a block out of order and ::Stream is ignoring this block, then retrying.

## Problem: What does the `Stream behind` error mean?

```
W, [2017-10-09T17:15:59.164484 #6231]  WARN -- : Stream behind by 6118 blocks (about 305.9 minutes).
```

## Solution:

This is an error produced by `::Stream` when it notices that the current block is falling too far behind the head block.  One solution is to just restart the stream and see if it happens again.  If you see a message like this occasionally, but otherwise the stream seems to keep up, it probably was able to recover on its own.

There can be several root causes. Resources like memory and CPU might be taxed.  The network connection might be too slow for what you're doing.  Remember, you're downloading each and every block, not just the operations you want.

If you have excluded system resources as the root cause, then you should take a look at your code.  If you're doing anything that takes longer than 3 seconds per block, `::Stream` can fall behind.  When this happens, `::Stream` will try to catch up without displaying a warning.  But once you fall 400 blocks behind (~20 minutes), you'll start to get the warning messages.

Verify your code is not doing too much between blocks.

## Problem: I'm getting an endless loop: `#<OpenSSL::SSL::SSLError: SSL_connect SYSCALL returned=5 errno=0 state=error: certificate verify failed>`

## Solution:

You're probably creating too many threads or you don't have enough resources for what you're doing.  One option for you is to avoid persistent HTTP by passing `persist: false`.

Doing this will impact performance because each API call will be a separate socket call.  All of the constructors accept `persist: false`., e.g.:

```ruby
api = Radiator::Api.new(persist: false)
```

... or ...

```ruby
stream = Radiator::Stream.new(persist: false)
```

... or ...

```ruby
tx = Radiator::Transaction.new(options.merge(persist: false, wif: wif))
```

Also see troubleshooting discussion about this situation:

https://github.com/inertia186/radiator/issues/12

## Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://github.com/inertia186/radiator.git`
* Navigate into the new folder
  * `cd radiator`
* Basic tests can be invoked as follows:
  * `rake`
* To run tests with parallelization and local code coverage:
  * `HELL_ENABLED=true rake`
* To run a stream test on the live STEEM blockchain with debug logging enabled:
  * `LOG=DEBUG rake test_live_stream`

---

<center>
  <img src="http://www.steemimg.com/images/2016/08/19/RadiatorCoolingFan-54in-Webfdcb1.png" />
</center>

See my previous Ruby How To posts in: [#radiator](https://steemit.com/created/radiator) [#ruby](https://steemit.com/created/ruby)

## Get in touch!

If you're using Radiator, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on STEEM.
  
## License

I don't believe in intellectual "property".  If you do, consider Radiator as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
