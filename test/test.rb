require 'predictionio'
require 'date'
require 'test/unit'

class TestPredictionIO < MiniTest::Unit::TestCase
  if ENV["APPKEY"] then
    APPKEY = ENV["APPKEY"]
  else
    APPKEY = "6MBUgJBRQdjPBtYIIqNSt3uIK6XaH3Wv0iFQvSzaImeIQHJEOUXtkj88EO39LtPn"
  end
  if ENV["APIURL"] then
    APIURL = ENV["APIURL"]
  else
    APIURL = "http://localhost:8000"
  end
  APITHREADS = 1

  def test_appkey
    client = PredictionIO::Client.new("foobar", APITHREADS, APIURL)
    assert_equal(client.appkey, "foobar")
  end

  def test_get_status
    client = PredictionIO::Client.new("foobar", APITHREADS, APIURL)
    assert_equal("PredictionIO Output API is online.", client.get_status)
  end

  def test_user
    client = PredictionIO::Client.new(APPKEY, APITHREADS, APIURL)
    client.create_user("ruby_foobar")
    assert_equal("ruby_foobar", client.get_user("ruby_foobar")["uid"], "uid: ruby_foobar")
    client.delete_user("ruby_foobar")
    client.create_user("ruby_barbaz",
                       "gender" => "F",
                       "bday" => "1985-05-05",
                       "latitude" => 21.109,
                       "longitude" => -48.7479,
                       "inactive" => true)
    ruby_barbaz = client.get_user("ruby_barbaz")
    assert_equal("ruby_barbaz", ruby_barbaz["uid"], "uid: ruby_barbaz")
    #assert_equal("F", ruby_barbaz["gender"], "gender: F")
    assert_equal(21.109, ruby_barbaz["latitude"], "lat: 21.109")
    assert_equal(-48.7479, ruby_barbaz["longitude"], "lng: -48.7479")
    #assert_equal("1985-05-05", ruby_barbaz["bday"], "bday: 1985-05-05")
    assert(ruby_barbaz["inactive"], "inactive: true")
    client.delete_user("ruby_barbaz")
  end

  def test_item
    client = PredictionIO::Client.new(APPKEY, APITHREADS, APIURL)
    client.create_item("ruby_barbaz",
                       ["218", "55"],
                       "latitude" => -58.24089,
                       "longitude" => 48.17890,
                       "startT" => Time.at(478308922000))
    assert_raises(PredictionIO::Client::ItemNotFoundError) { client.get_item("randomstuff") }
    ruby_barbaz = client.get_item("ruby_barbaz")
    assert_equal("ruby_barbaz", ruby_barbaz["iid"], "iid: ruby_barbaz")
    assert(ruby_barbaz["itypes"].include?("218"), "itypes: 218")
    assert(ruby_barbaz["itypes"].include?("55"), "itypes: 55")
    assert_equal(-58.24089, ruby_barbaz["latitude"], "lat: -58.24089")
    assert_equal(48.1789, ruby_barbaz["longitude"], "lng: 48.1789")
    assert_equal(Time.at(478308922000), ruby_barbaz["startT"], "startT: 478308922000")
    client.delete_item("ruby_barbaz")
  end

  def test_u2i
    client = PredictionIO::Client.new(APPKEY, APITHREADS, APIURL)
    client.user_rate_item("foo1", "bar2", 4)
    client.user_like_item("foo2", "bar4")
    client.user_dislike_item("foo4", "bar8")
    client.user_view_item("foo8", "bar16")
    client.user_conversion_item("foo16", "bar32")
  end

  def test_itemrec
    client = PredictionIO::Client.new(APPKEY, APITHREADS, APIURL)
    iids = client.get_itemrec_top_n("test", "218", 5)
    assert(iids.include?("itemrec"))
    assert(iids.include?("218"))
    assert(iids.include?("1"))
    assert(iids.include?("foo"))
    assert(iids.include?("bar"))
    assert_equal(iids.length, 5)
  end
end
