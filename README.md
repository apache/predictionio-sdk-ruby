# PredictionIO Ruby SDK

[![Build Status](https://travis-ci.org/PredictionIO/PredictionIO-Ruby-SDK.svg?branch=develop)](https://travis-ci.org/PredictionIO/PredictionIO-Ruby-SDK)
[![Code Climate](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK.png)](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK)
[![Dependency Status](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK.svg)](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK)
[![Gem Version](https://badge.fury.io/rb/predictionio.svg)](http://badge.fury.io/rb/predictionio)

The Ruby SDK provides a convenient wrapper for the PredictionIO API.
It allows you to quickly record your users' behavior
and retrieve personalized predictions for them.

## Installation

Ruby 1.9.3+ required!

The module is published to [RubyGems](http://rubygems.org/gems/predictionio) and can be installed directly by:

```sh
gem install predictionio
```

Or using [Bundler](http://bundler.io/) with:

```
gem 'predictionio', '0.9.0'
```

## Send an Event to PredictionIO

Connect to the Event Server with:

```ruby
# Define environment variables.
ENV['PIO_THREADS'] = 50 # For async requests.
ENV['PIO_EVENT_SERVER_URL'] = 'http://localhost:7070'
ENV['PIO_ACCESS_KEY'] = 'YOUR_ACCESS_KEY' # Find your access key with: `$ pio app list`.

# Create PredictionIO event client.
client = PredictionIO::EventClient.new(ENV['PIO_ACCESS_KEY'], ENV['PIO_EVENT_SERVER_URL'], ENV['PIO_THREADS'])
```

### Set a User

```ruby
user_id = User.find(...).id

client.create_event(
  '$set',
  'user',
  user_id
)

```

### Set an Item

```ruby
item_id = Model.find(...).id

client.create_event(
  '$set',
  'item',
  item_id,
  { 'properties' => { 'categories' => ['Category 1', 'Category 2'] } }
)
```

### Record an Event

```ruby
client.create_event(
  'rate',
  'user',
  user_id, {
    'targetEntityType' => 'item',
    'targetEntityId' => item_id,
    'properties' => { 'rating' => 10 }
  }
)
```

### Async

To use an async request simply change `create_event` to `acreate_event`. The
asynchronous method wont though an error though so it's best to start with the
synchronous one.

## Query PredictionIO

Connect to the PredictionIO Engine with:

```ruby
# Define environmental variables.
ENV['PIO_ENGINE_URL'] = 'http://localhost:8000'

# Create PredictionIO engine client.
client = PredictionIO::EngineClient.new(ENV['PIO_ENGINE_URL'])
```

### Get a Recomendation

```ruby
# Get 5 recommendations for items similar to 10, 20, 30.
response = client.send_query(items: [10, 20, 30], num: 5)
```

## Documentation

RDoc is [available online](http://docs.prediction.io/ruby/api/PredictionIO.html).

## Forum

View [Google Group](https://groups.google.com/group/predictionio-user)

## Issue Tracker

Use [JIRA](https://predictionio.atlassian.net) or [GitHub Issues](https://github.com/PredictionIO/PredictionIO-Ruby-SDK/issues).

## Contributing

We follow the [git-flow]
(http://nvie.com/posts/a-successful-git-branching-model/) model where all
active development goes to the develop branch, and releases go to the master
branch. Pull requests should be made against the develop branch and include
relevant tests, if applicable. Please sign
our [Contributor Agreement](http://prediction.io/cla) before submitting a pull request.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
