# PredictionIO Ruby SDK

[![Build Status](https://travis-ci.org/PredictionIO/PredictionIO-Ruby-SDK.svg?branch=develop)](https://travis-ci.org/PredictionIO/PredictionIO-Ruby-SDK)
[![Code Climate](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK.png)](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK)
[![Dependency Status](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK.svg)](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK)
[![Gem Version](https://badge.fury.io/rb/predictionio.svg)](http://badge.fury.io/rb/predictionio)

The Ruby SDK provides a convenient wrapper for the PredictionIO API.
It allows you to quickly record your users' behavior
and retrieve personalized predictions for them.

## Documentation

Full Ruby SDK documentation can be found [here](http://docs.prediction.io/ruby/api/PredictionIO.html).

Please see the [PredictionIO App Integration Overview](http://docs.prediction.io/appintegration/) to understand how the SDK can be used to integrate PredictionIO Event Server and Engine with your application.

## Installation

Ruby 1.9.3+ required!

The module is published to [RubyGems](http://rubygems.org/gems/predictionio) and can be installed directly by:

```sh
gem install predictionio
```

Or using [Bundler](http://bundler.io/) with:

```
gem 'predictionio', '0.9.1'
```

## Sending Events to Event Server

Please refer to [Event Server documentation](https://docs.prediction.io/datacollection/) for event format and how the data can be collected from your app.

### Instantiate Event Client and connect to PredictionIO Event Server

```ruby
require 'predictionio'

# Define environment variables.
ENV['PIO_THREADS'] = '50' # For async requests.
ENV['PIO_EVENT_SERVER_URL'] = 'http://localhost:7070'
ENV['PIO_ACCESS_KEY'] = 'YOUR_ACCESS_KEY' # Find your access key with: `$ pio app list`.

# Create PredictionIO event client.
client = PredictionIO::EventClient.new(ENV['PIO_ACCESS_KEY'], ENV['PIO_EVENT_SERVER_URL'], Integer(ENV['PIO_THREADS']))
```

### Create a `$set` user event and send it to Event Server

```ruby
client.create_event(
  '$set',
  'user',
  user_id
)

```

### Create a `$set` item event and send it to Event Server

```ruby
client.create_event(
  '$set',
  'item',
  item_id,
  { 'properties' => { 'categories' => ['Category 1', 'Category 2'] } }
)
```

### Create a user 'rate' item event and send it to Event Server

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

### Asynchronous request

To send an async request, simply use the `acreate_event` method instead of `create_event`. Be aware that the
asynchronous method does not throw errors. It's best to use the synchronous method when first getting started.

## Query PredictionIO Engine

### Connect to the Engine:

```ruby
# Define environmental variables.
ENV['PIO_ENGINE_URL'] = 'http://localhost:8000'

# Create PredictionIO engine client.
client = PredictionIO::EngineClient.new(ENV['PIO_ENGINE_URL'])
```

### Send a prediction query to the engine and get the predicted result:

```ruby
# Get 5 recommendations for items similar to 10, 20, 30.
response = client.send_query(items: [10, 20, 30], num: 5)
```

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
