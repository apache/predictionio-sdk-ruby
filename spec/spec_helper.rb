require 'coveralls'
require 'json'
require 'webmock/rspec'

Coveralls.wear!
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Events API
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: 'register',
                                 entityType: 'user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef00'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$set',
                                 entityType: 'pio_user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef01'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$unset',
                                 entityType: 'pio_user', entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef02'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$set',
                                 entityType: 'pio_item', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef03'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$unset',
                                 entityType: 'pio_item', entityId: 'foobar',
                                 properties: { bar: 'baz' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef04'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: 'greet',
                                 entityType: 'pio_user', entityId: 'foobar',
                                 targetEntityType: 'pio_item',
                                 targetEntityId: 'barbaz',
                                 properties: { dead: 'beef' }))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef05'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$delete',
                                 entityType: 'pio_user', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef06'))
    stub_request(:post, 'http://fakeapi.com:8000/events.json')
      .with(body: hash_including(appId: 1, event: '$delete',
                                 entityType: 'pio_item', entityId: 'foobar'))
      .to_return(status: 201, body: JSON.generate(eventId: 'deadbeef07'))

    # Engine Instance
    stub_request(:post, 'http://fakeapi.com:8000/')
      .with(body: { uid: 'foobar' })
      .to_return(status: 200, body: JSON.generate(iids: %w(dead beef)),
                 headers: {})

    # Users API
    stub_request(:post, 'http://fakeapi.com:8000/users.json')
      .with(body: { pio_appkey: 'foobar', pio_uid: 'foo' })
      .to_return(status: 201, body: '', headers: {})
    stub_request(:get, 'http://fakeapi.com:8000/users/foo.json')
      .with(query: hash_including(pio_appkey: 'foobar'))
      .to_return(status: 200, body: JSON.generate(pio_uid: 'foo'), headers: {})
    stub_request(:delete, 'http://fakeapi.com:8000/users/foo.json')
      .with(query: hash_including(pio_appkey: 'foobar'))
      .to_return(status: 200, body: '', headers: {})

    # Items API
    stub_request(:post, 'http://fakeapi.com:8000/items.json')
      .with(body: { pio_appkey: 'foobar', pio_iid: 'bar',
                    pio_itypes: 'dead,beef' })
      .to_return(status: 201, body: '', headers: {})
    stub_request(:get, 'http://fakeapi.com:8000/items/bar.json')
      .with(query: hash_including(pio_appkey: 'foobar'))
      .to_return(status: 200,
                 body: JSON.generate(pio_iid: 'bar', pio_itypes: %w(dead beef)),
                 headers: {})
    stub_request(:delete, 'http://fakeapi.com:8000/items/bar.json')
      .with(query: hash_including(pio_appkey: 'foobar'))
      .to_return(status: 200, body: '', headers: {})

    # U2I Actions API
    stub_request(:post, 'http://fakeapi.com:8000/actions/u2i.json')
      .with(body: { pio_action: 'view', pio_appkey: 'foobar', pio_iid: 'bar',
                    pio_uid: 'foo' })
      .to_return(status: 201, body: '', headers: {})

    # Item Recommendation API
    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemrec/itemrec-engine/topn.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_n: '10',
                                  pio_uid: 'foo'))
      .to_return(status: 200, body: JSON.generate(pio_iids: %w(x y z)),
                 headers: {})

    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemrec/itemrec-engine/topn.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_n: '10',
                                  pio_uid: 'foo', pio_attributes: 'name'))
      .to_return(status: 200,
                 body: JSON.generate(pio_iids: %w(x y z), name: %w(a b c)),
                 headers: {})

    # Item Recommendation API
    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemrank/itemrank-engine/ranked.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_iids: 'y,z,x',
                                  pio_uid: 'foo'))
      .to_return(status: 200, body: JSON.generate(pio_iids: %w(x y z)),
                 headers: {})

    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemrank/itemrank-engine/ranked.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_iids: 'y,x,z',
                                  pio_uid: 'foo', pio_attributes: 'name'))
      .to_return(status: 200,
                 body: JSON.generate(pio_iids: %w(x y z), name: %w(a b c)),
                 headers: {})

    # Item Similarity API
    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemsim/itemsim-engine/topn.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_n: '10',
                                  pio_iid: 'bar'))
      .to_return(status: 200,
                 body: JSON.generate(pio_iids: %w(x y z)),
                 headers: {})

    stub_request(
      :get,
      'http://fakeapi.com:8000/engines/itemsim/itemsim-engine/topn.json')
      .with(query: hash_including(pio_appkey: 'foobar', pio_n: '10',
                                  pio_iid: 'bar', pio_attributes: 'name'))
      .to_return(status: 200,
                 body: JSON.generate('pio_iids' => %w(x y z),
                                     'name' => %w(a b c)),
                 headers: {})
  end
end
