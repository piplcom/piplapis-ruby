require 'helper'
require 'json'

describe Pipl::Client do

  before do
    Pipl.reset!
  end

  after do
    Pipl.reset!
  end

  describe 'module configuration' do

    before do
      Pipl.reset!
      Pipl.configure do |config|
        Pipl::Configurable.keys.each do |key|
          config.send("#{key}=", "Some #{key}")
        end
      end
    end

    after do
      Pipl.reset!
    end

    it 'inherits the module configuration' do
      client = Pipl::Client.new
      Pipl::Configurable.keys.each do |key|
        expect(client.instance_variable_get(:"@#{key}")).to eq("Some #{key}")
      end
    end

    describe 'with class level configuration' do

      before do
        @opts = {
            api_key: 'test api key',
            minimum_probability: 0.7,
            show_sources: Pipl::Configurable.SHOW_SOURCES_ALL
        }
      end

      it 'overrides module configuration' do
        client = Pipl::Client.new(@opts)
        expect(client.api_key).to eq('test api key')
        expect(client.minimum_probability).to eq(0.7)
        expect(client.show_sources).to eq(Pipl::Configurable.SHOW_SOURCES_ALL)
        expect(client.api_endpoint).to eq(Pipl.api_endpoint)
        expect(client.user_agent).to eq(Pipl.user_agent)
      end

      it 'can set configuration after initialization' do
        client = Pipl::Client.new
        client.configure do |config|
          @opts.each do |key, value|
            config.send("#{key}=", value)
          end
        end
        expect(client.api_key).to eq('test api key')
        expect(client.minimum_probability).to eq(0.7)
        expect(client.show_sources).to eq(Pipl::Configurable.SHOW_SOURCES_ALL)
        expect(client.api_endpoint).to eq(Pipl.api_endpoint)
        expect(client.user_agent).to eq(Pipl.user_agent)
      end
    end
  end

  describe 'when making requests' do

    before do
      Pipl.reset!
      @client = Pipl.client
    end

    it 'sets a default user agent' do
      request = stub_post.
          with(headers: {user_agent: Pipl::Default.user_agent})
      @client.search email: 'clark.kent@example.com'
      assert_requested request
    end

    it 'sets a custom user agent' do
      user_agent = 'Mozilla/5.0 I am Spartacus!'
      request = stub_post.
          with(headers: {user_agent: user_agent})
      client = Pipl::Client.new(user_agent: user_agent)
      client.search email: 'clark.kent@example.com'
      assert_requested request
    end
  end

end
