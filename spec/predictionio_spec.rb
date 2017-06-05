require 'predictionio'
require 'spec_helper'

describe PredictionIO do
  let(:access_key) { 1 }
  let(:event_client) { PredictionIO::EventClient.new(access_key, 'http://fakeapi.com:7070', 10) }
  let(:engine_client) { PredictionIO::EngineClient.new('http://fakeapi.com:8000', 10) }

  describe 'Events API' do
    it 'create_event should create an event' do
      response = event_client.create_event('register', 'user', 'foobar')
      expect(response.code).to eq('201')
    end

    context 'with http stub (for channel test)' do
      before(:each) do
        success_response = Net::HTTPCreated.new('HTTP/1.1', '201', 'Created')
        success_response.body = JSON.generate(eventId: 'deadbeef00')
        expect_any_instance_of(PredictionIO::Connection).to receive(:apost).and_return(double(get: success_response))
      end

      it 'create_event should have channel option (symbol)' do
        expect(PredictionIO::AsyncRequest).
          to receive(:new).with("/events.json?accessKey=#{access_key}&channel=test-channel",
                                {
                                  "eventTime" => "2017-03-22T12:26:35+03:00", "event" => "$set",
                                  "entityType" => "Session", "entityId" => "42"
                                }.to_json)
        event_client.create_event('$set', 'Session', '42',
                                  {channel: 'test-channel', 'eventTime' => "2017-03-22T12:26:35+03:00"})
      end

      it 'create_event should process channel option (string)' do
        expect(PredictionIO::AsyncRequest).
          to receive(:new).with("/events.json?accessKey=#{access_key}&channel=test-channel",
                                {
                                  "eventTime" => "2017-03-22T12:26:35+03:00", "event" => "$set",
                                  "entityType" => "Session", "entityId" => "42"
                                }.to_json)
        response = event_client.create_event('$set', 'Session', '42',
                                             { 'channel' => 'test-channel', 'eventTime' => "2017-03-22T12:26:35+03:00" })
        expect(response.code).to eq('201')
      end

      it 'create_event should work without channel option' do
        expect(PredictionIO::AsyncRequest).
          to receive(:new).with("/events.json?accessKey=#{access_key}",
                                {
                                  "eventTime" => "2017-03-22T12:26:35+03:00", "event" => "$set",
                                  "entityType" => "Session", "entityId" => "42"
                                }.to_json)
        response = event_client.create_event('$set', 'Session', '42',
                                             { 'eventTime' => "2017-03-22T12:26:35+03:00" })
        expect(response.code).to eq('201')
      end
    end

    it 'create_event should post real request with channel option' do
      response = event_client.create_event('$set', 'Session', '42',
                                           { 'channel' => 'test-channel', 'eventTime' => "2017-03-22T12:26:35+03:00" })
      expect(response.code).to eq('201')
    end

    it 'create_event should not raise an error' do
      response = event_client.create_event('register', 'user', 'foobar')
      expect{ response }.to_not raise_error
    end

    it 'set_user should set user properties' do
      response = event_client.set_user('foobar')
      expect(response.code).to eq('201')
    end

    it 'set_user should not raise an error' do
      response = event_client.set_user('foobar')
      expect{ response }.to_not raise_error
    end

    it 'unset_user should unset user properties' do
      response = event_client.unset_user('foobar', 'properties' => { 'bar' => 'baz' })
      expect(response.code).to eq('201')
    end

    it 'unset_user should not raise an error' do
      response = event_client.unset_user('foobar', 'properties' => { 'bar' => 'baz' })
      expect{ response }.to_not raise_error
    end

    it 'set_item should set item properties' do
      response = event_client.set_item('foobar')
      expect(response.code).to eq('201')
    end

    it 'set_item should should not raise an error' do
      response = event_client.set_item('foobar')
      expect{ response }.to_not raise_error
    end

    it 'unset_item should unset item properties' do
      response = event_client.unset_item('foobar', 'properties' => { 'bar' => 'baz' })
      expect(response.code).to eq('201')
    end

    it 'unset_item should not raise an error' do
      response = event_client.unset_item('foobar', 'properties' => { 'bar' => 'baz' })
      expect{ response }.to_not raise_error
    end

    it 'record_user_action_on_item should record a U2I action' do
      response = event_client.record_user_action_on_item('greet', 'foobar', 'barbaz', 'properties' => { 'dead' => 'beef' })
      expect(response.code).to eq('201')
    end

    it 'record_user_action_on_item should not raise an error' do
      response = event_client.record_user_action_on_item('greet', 'foobar', 'barbaz', 'properties' => { 'dead' => 'beef' })
      expect{ response }.to_not raise_error
    end

    it 'delete_user should delete a user' do
      response = event_client.delete_user('foobar')
      expect(response.code).to eq('201')
    end

    it 'delete_user should not raise an error' do
      response = event_client.delete_user('foobar')
      expect{ response }.to_not raise_error
    end

    it 'delete_item should delete an item' do
      response = event_client.delete_item('foobar')
      expect(response.code).to eq('201')
    end

    it 'delete_item should not raise an error' do
      response = event_client.delete_item('foobar')
      expect{ response }.to_not raise_error
    end
  end

  describe 'Engine Client' do
    it 'send_query should get predictions' do
      predictions = engine_client.send_query('uid' => 'foobar')
      expect(predictions).to eq('iids' => %w(dead beef))
    end
  end
end
