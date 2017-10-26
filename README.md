<!--
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Apache PredictionIO Ruby SDK

[![Build Status](https://api.travis-ci.org/apache/incubator-predictionio-sdk-ruby.svg?branch=develop)](https://github.com/apache/incubator-predictionio-sdk-ruby)
[![Code Climate](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK.png)](https://codeclimate.com/github/PredictionIO/PredictionIO-Ruby-SDK)
[![Dependency Status](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK.svg)](https://gemnasium.com/PredictionIO/PredictionIO-Ruby-SDK)
[![Gem Version](https://badge.fury.io/rb/predictionio.svg)](http://badge.fury.io/rb/predictionio)

The Ruby SDK provides a convenient wrapper for PredictionIO Event Server API and
Engine API. It allows you to quickly record your users' behavior and retrieve
personalized predictions for them.

## Documentation

Full Ruby SDK documentation can be found [here](http://www.rubydoc.info/github/apache/incubator-predictionio-sdk-ruby).

Please see the [PredictionIO App Integration
Overview](http://predictionio.apache.org/appintegration/) to
understand how the SDK can be used to integrate PredictionIO Event Server and
Engine with your application.

## Installation

Ruby 2+ required!

The module is published to [RubyGems](http://rubygems.org/gems/predictionio) and
can be installed directly by:

```sh
gem install predictionio
```

Or using [Bundler](http://bundler.io/) with:

```
gem 'predictionio', '0.12.0'
```

## Sending Events to Event Server

Please refer to [Event Server
documentation](http://predictionio.apache.org/datacollection/) for
event format and how the data can be collected from your app.

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

### Create a `$set` item event and send it to Event Server to specific channel

*NOTE:* channels are supported in PIO version >= 0.9.2 only. Channel must be created first.

```ruby
client.create_event(
  '$set',
  'item',
  item_id,
  { 'properties' => { 'categories' => ['Category 1', 'Category 2'], 'channel' => 'test-channel'} }
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

To send an async request, simply use the `acreate_event` method instead of
`create_event`. Be aware that the asynchronous method does not throw errors.
It's best to use the synchronous method when first getting started.

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

## Mailing List

Please use the Apache mailing lists. Subscription instructions are
[here](http://predictionio.apache.org/support/).

## Issue Tracker

Use [the Apache JIRA](https://issues.apache.org/jira/browse/PIO), and file any
issues under the `Ruby SDK` component.

## Contributing

Please follow these
[instructions](http://predictionio.apache.org/community/contribute-code/).

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
