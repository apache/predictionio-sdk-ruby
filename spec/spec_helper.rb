require 'coveralls'
require 'json'
require 'webmock/rspec'

Coveralls.wear!
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Events API
    %w(
      http://fakeapi.com:7070/events.json?accessKey=1&channel=test-channel
    ).each do |url|
      stub_request(:post, url)
        .with(body: hash_including(event: '$set',
                                   entityType: 'Session',
                                   entityId: '42'))
        .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef00'))
    end

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: 'register',
                                 entityType: 'user',
                                 entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef00'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$set',
                                 entityType: 'user',
                                 entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef01'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$unset',
                                 entityType: 'user',
                                 entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef02'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$set',
                                 entityType: 'item',
                                 entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef03'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$unset',
                                 entityType: 'item',
                                 entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef04'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: 'greet',
                                 entityType: 'user',
                                 entityId: 'foobar',
                                 targetEntityType: 'item',
                                 targetEntityId: 'barbaz',
                                 properties: { dead: 'beef' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef05'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$delete',
                                 entityType: 'user',
                                 entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef06'))

    stub_request(:post, 'http://fakeapi.com:7070/events.json?accessKey=1')
      .with(body: hash_including(event: '$delete',
                                 entityType: 'item',
                                 entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef07'))

    # Engine Instance
    stub_request(:post, 'http://fakeapi.com:8000/queries.json')
      .with(body: { uid: 'foobar' })
      .to_return(status: 200, body: JSON.generate(iids: %w(dead beef)), headers: {})
  end
end
