# radiator

![radiator](https://www.steemimg.com/images/2016/08/19/RadiatorCoolingFan-54in-Webfdcb1.png)[![Build Status](https://travis-ci.org/inertia186/radiator.svg?branch=master)](https://travis-ci.org/inertia186/radiator) [![Code Climate](https://codeclimate.com/github/inertia186/radiator/badges/gpa.svg)](https://codeclimate.com/github/inertia186/radiator) [![Test Coverage](https://codeclimate.com/github/inertia186/radiator/badges/coverage.svg)](https://codeclimate.com/github/inertia186/radiator)

STEEM Ruby API Client

### Installation

Add the gem to your Gemfile:

    gem 'radiator', github: 'inertia186/radiator'
    
Then:

    $ bundle install

### Usage

```ruby
require 'radiator'

api = Radiator::Api.new
response = api.get_dynamic_global_properties
response.result.virtual_supply
=> "135377049.603 STEEM"
```

### Follower API

```ruby
api = Radiator::FollowerApi.new
response = @api.get_followers('inertia', 0, 'blog', 100)
response.result.map(&:follower)
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

## Tests

* Clone the client repository into a directory of your choice:
  * `git clone https://github.com/inertia186/radiator.git`
* Navigate into the new folder
  * `cd radiator`
* Basic tests can be invoked as follows:
  * `rake`
* To run tests with parallelization and local code coverage:
  * `HELL_ENABLED=true rake`

## Get in touch!

If you're using Radiator, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on STEEM.
  
## License

I don't believe in intellectual "property".  If you do, consider Radiator as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
