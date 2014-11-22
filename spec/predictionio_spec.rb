require 'predictionio'
require 'spec_helper'

event_client = PredictionIO::EventClient.new(1, 'http://fakeapi.com:8000', 10)
engine_client = PredictionIO::EngineClient.new('http://fakeapi.com:8000', 10)

describe PredictionIO do
  describe 'Events API' do
    it 'create_event should create an event' do
      response = event_client.create_event('register', 'user', 'foobar')
      expect(response).to_not raise_error
    end
    it 'set_user should set user properties' do
      response = event_client.set_user('foobar')
      expect(response).to_not raise_error
    end
    it 'unset_user should unset user properties' do
      response = event_client.unset_user('foobar',
                                         'properties' => { 'bar' => 'baz' })
      expect(response).to_not raise_error
    end
    it 'set_item should set item properties' do
      response = event_client.set_item('foobar')
      expect(response).to_not raise_error
    end
    it 'unset_item should unset item properties' do
      response = event_client.unset_item('foobar',
                                         'properties' => { 'bar' => 'baz' })
      expect(response).to_not raise_error
    end
    it 'record_user_action_on_item should record a U2I action' do
      response = event_client.record_user_action_on_item(
        'greet', 'foobar', 'barbaz', 'properties' => { 'dead' => 'beef' })
      expect(response).to_not raise_error
    end
    it 'delete_user should delete a user' do
      response = event_client.delete_user('foobar')
      expect(response).to_not raise_error
    end
    it 'delete_item should delete an item' do
      response = event_client.delete_item('foobar')
      expect(response).to_not raise_error
    end
  end

  describe 'Engine Client' do
    it 'send_query should get predictions' do
      predictions = engine_client.send_query('uid' => 'foobar')
      expect(predictions).to eq('iids' => %w(dead beef))
    end
  end
end
