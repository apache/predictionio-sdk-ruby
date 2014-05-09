require 'coveralls'
require 'json'
require 'webmock/rspec'

Coveralls.wear!
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Users API
    stub_request(:post, "http://fakeapi.com:8000/users.json").
      with(:body => {"pio_appkey" => "foobar", "pio_uid" => "foo"}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:get, "http://fakeapi.com:8000/users/foo.json").
      with(:query => hash_including({"pio_appkey" => "foobar"})).
      to_return(:status => 200, :body => JSON.generate({"pio_uid" => "foo"}), :headers => {})
    stub_request(:delete, "http://fakeapi.com:8000/users/foo.json").
      with(:query => hash_including({"pio_appkey" => "foobar"})).
      to_return(:status => 200, :body => "", :headers => {})

    # Items API
    stub_request(:post, "http://fakeapi.com:8000/items.json").
      with(:body => {"pio_appkey" => "foobar", "pio_iid" => "bar", "pio_itypes" => "dead,beef"}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:get, "http://fakeapi.com:8000/items/bar.json").
      with(:query => hash_including({"pio_appkey" => "foobar"})).
      to_return(:status => 200, :body => JSON.generate({"pio_iid" => "bar", "pio_itypes" => ["dead", "beef"]}), :headers => {})
    stub_request(:delete, "http://fakeapi.com:8000/items/bar.json").
      with(:query => hash_including({"pio_appkey" => "foobar"})).
      to_return(:status => 200, :body => "", :headers => {})

    # U2I Actions API
    stub_request(:post, "http://fakeapi.com:8000/actions/u2i.json").
      with(:body => {"pio_action" => "view", "pio_appkey" => "foobar", "pio_iid" => "bar", "pio_uid" => "foo"}).
      to_return(:status => 201, :body => "", :headers => {})

    # Item Recommendation API
    stub_request(:get, "http://fakeapi.com:8000/engines/itemrec/itemrec-engine/topn.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_n" => "10", "pio_uid" => "foo")).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"]}), :headers => {})

    stub_request(:get, "http://fakeapi.com:8000/engines/itemrec/itemrec-engine/topn.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_n" => "10", "pio_uid" => "foo", 'pio_attributes' => 'name')).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"], "name" => ["a", "b", "c"]}), :headers => {})

    # Item Recommendation API
    stub_request(:get, "http://fakeapi.com:8000/engines/itemrank/itemrank-engine/ranked.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_iids" => "y,z,x", "pio_uid" => "foo")).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"]}), :headers => {})

    stub_request(:get, "http://fakeapi.com:8000/engines/itemrank/itemrank-engine/ranked.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_iids" => "y,x,z", "pio_uid" => "foo", 'pio_attributes' => 'name')).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"], "name" => ["a", "b", "c"]}), :headers => {})

    # Item Similarity API
    stub_request(:get, "http://fakeapi.com:8000/engines/itemsim/itemsim-engine/topn.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_n" => "10", "pio_iid" => "bar")).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"]}), :headers => {})

    stub_request(:get, "http://fakeapi.com:8000/engines/itemsim/itemsim-engine/topn.json").
      with(:query => hash_including("pio_appkey" => "foobar", "pio_n" => "10", "pio_iid" => "bar", 'pio_attributes' => 'name')).
      to_return(:status => 200, :body => JSON.generate({"pio_iids" => ["x", "y", "z"], 'name' => ['a', 'b', 'c']}), :headers => {})
  end
end
