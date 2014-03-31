require 'predictionio'
require 'spec_helper'

client = PredictionIO::Client.new("foobar", 10, "http://fakeapi.com:8000")

describe PredictionIO do
  describe 'Users API' do
    it 'create_user should create a user' do
      response = client.create_user("foo")
      expect(response).to_not raise_error
    end
    it 'get_user should get a user' do
      response = client.get_user("foo")
      expect(response).to eq({"pio_uid" => "foo"})
    end
    it 'delete_user should delete a user' do
      response = client.delete_user("foo")
      expect(response).to_not raise_error
    end
  end
  describe 'Items API' do
    it 'create_item should create a item' do
      response = client.create_item("bar", ["dead", "beef"])
      expect(response).to_not raise_error
    end
    it 'get_item should get a item' do
      response = client.get_item("bar")
      expect(response).to eq({"pio_iid" => "bar", "pio_itypes" => ["dead", "beef"]})
    end
    it 'delete_item should delete a item' do
      response = client.delete_item("bar")
      expect(response).to_not raise_error
    end
  end
  describe 'U2I API' do
    it 'record_action_on_item should record an action' do
      client.identify("foo")
      response = client.record_action_on_item("view", "bar")
      expect(response).to_not raise_error
    end
  end
end
