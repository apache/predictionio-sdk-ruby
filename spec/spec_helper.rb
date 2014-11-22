require 'coveralls'
require 'json'
require 'webmock/rspec'

Coveralls.wear!
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Events API
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: 'register',
                                 entityType: 'user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef00'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$set',
                                 entityType: 'pio_user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef01'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$unset',
                                 entityType: 'pio_user', entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef02'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$set',
                                 entityType: 'pio_item', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef03'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$unset',
                                 entityType: 'pio_item', entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef04'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: 'greet',
                                 entityType: 'pio_user', entityId: 'foobar',
                                 targetEntityType: 'pio_item',
                                 targetEntityId: 'barbaz',
                                 properties: { dead: 'beef' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef05'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$delete',
                                 entityType: 'pio_user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef06'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json?accessKey=1')
      .with(body: hash_including(event: '$delete',
                                 entityType: 'pio_item', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef07'))

    # Engine Instance
    stub_request(:post, 'http://fakeapi.com:8000/queries.json')
      .with(body: { uid: 'foobar' })
      .to_return(status: 200, body: JSON.generate(iids: %w(dead beef)),
                 headers: {})
  end
end
