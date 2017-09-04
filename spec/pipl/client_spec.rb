require 'json'
require_relative '../helper'

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
            minimum_match: 0.9,
            show_sources: Pipl::Configurable::SHOW_SOURCES_ALL,
            match_requirements: 'email & phone',
            source_category_requirements: 'personal_profiles',
            infer_persons: true
        }
      end

      it 'overrides module configuration' do
        client = Pipl::Client.new(@opts)
        expect(client.api_key).to eq('test api key')
        expect(client.minimum_probability).to eq(0.7)
        expect(client.minimum_match).to eq(0.9)
        expect(client.show_sources).to eq(Pipl::Configurable::SHOW_SOURCES_ALL)
        expect(client.match_requirements).to eq('email & phone')
        expect(client.source_category_requirements).to eq('personal_profiles')
        expect(client.infer_persons).to eq(true)
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
        expect(client.minimum_match).to eq(0.9)
        expect(client.show_sources).to eq(Pipl::Configurable::SHOW_SOURCES_ALL)
        expect(client.match_requirements).to eq('email & phone')
        expect(client.source_category_requirements).to eq('personal_profiles')
        expect(client.infer_persons).to eq(true)
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

    describe 'creates search request from parameters' do

      it 'uses a search_token first' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        @client.search search_pointer: 'search_pointer'
        expect(request).to have_been_requested
      end

      it 'uses a given person' do
        person = Pipl::Person.new
        person.add_field Pipl::Name.new first: 'first', last: 'last'
        person.add_field Pipl::Address.new country: 'US', state: 'AZ'

        request = stub_post.
            with(body: {person: person.to_hash.to_json}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        @client.search person: person
        expect(request).to have_been_requested
      end

      it 'collects single fields shorthands to a person' do
        person = Pipl::Person.new
        person.add_field Pipl::Email.new address: 'test@example.com'
        person.add_field Pipl::Username.new content: 'username@service'
        person.add_field Pipl::Phone.new raw: '+44 123456789'
        person.add_field Pipl::Name.new raw: 'raw name'
        person.add_field Pipl::Name.new first: 'first', middle: 'middle', last: 'last'
        person.add_field Pipl::Address.new raw: 'raw address'
        person.add_field Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix', zip_code: '85001'
        person.add_field Pipl::DOB.from_age_range 20, 30

        request = stub_post.
            with(body: {person: person.to_hash.to_json},
                 query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        params = {
            email: 'test@example.com',
            username: 'username@service',
            phone: '+44 123456789',
            first_name: 'first',
            middle_name: 'middle',
            last_name: 'last',
            raw_name: 'raw name',
            country: 'US',
            state: 'AZ',
            city: 'Phoenix',
            zip_code: '85001',
            raw_address: 'raw address',
            from_age: '20',
            to_age: '30',
        }
        @client.search params
        expect(request).to have_been_requested
      end

      it 'collects single fields shorthands to a person. Phone as number' do
        person = Pipl::Person.new
        person.add_field Pipl::Phone.new number: 123456789

        request = stub_post.
            with(body: {person: person.to_hash.to_json},
                 query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        params = {phone: 123456789 }
        @client.search params
        expect(request).to have_been_requested
      end

      it 'appends single fields to a given person' do
        person = Pipl::Person.new
        person.add_field Pipl::Name.new first: 'first', last: 'last'
        person.add_field Pipl::Address.new country: 'US', state: 'AZ'

        request = stub_post.
            with(body: {person: person.to_hash.merge!({emails: [{address: 'test@example.com'}]}).to_json},
                 query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        @client.search person: person, email: 'test@example.com'
        expect(request).to have_been_requested
      end

      it 'sets minimum_probability' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], minimum_probability: 0.7})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', minimum_probability: 0.7
        expect(request).to have_been_requested
      end

      it 'sets minimum_match' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], minimum_match: 0.9})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', minimum_match: 0.9
        expect(request).to have_been_requested
      end

      it 'sets hide_sponsored' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], hide_sponsored: 'false'})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', hide_sponsored: false
        expect(request).to have_been_requested
      end

      it 'sets live_feeds' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], live_feeds: 'true'})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', live_feeds: true
        expect(request).to have_been_requested
      end

      it 'sets show_sources' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], show_sources: Pipl::Configurable::SHOW_SOURCES_ALL})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', show_sources: Pipl::Configurable::SHOW_SOURCES_ALL
        expect(request).to have_been_requested
      end

      it 'sets show_sources boolean' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], show_sources: :true})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', show_sources: true, strict_validation: true
        expect(request).to have_been_requested
      end

      it 'sets match_requirements string' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], match_requirements: :'match_requirements'})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', match_requirements: 'match_requirements', strict_validation: true
        expect(request).to have_been_requested
      end

      it 'sets source_category_requirements string' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], source_category_requirements: :'source_category_requirements'})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', source_category_requirements: 'source_category_requirements', strict_validation: true
        expect(request).to have_been_requested
      end

      it 'sets infer_persons boolean' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent},
                 query: {key: ENV['PIPL_API_KEY'], infer_persons: :true})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com', infer_persons: true, strict_validation: true
        expect(request).to have_been_requested
      end

      it 'sets a default user agent' do
        request = stub_post.
            with(body: /.*/, headers: {user_agent: Pipl::Default.user_agent}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        @client.search email: 'test@example.com'
        expect(request).to have_been_requested
      end

      it 'sets a custom user agent' do
        user_agent = 'Mozilla/5.0 I am Spartacus!'
        request = stub_post.
            with(body: /.*/, headers: {user_agent: user_agent}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(empty_json_response)

        client = Pipl::Client.new(user_agent: user_agent)
        client.search email: 'test@example.com'
        expect(request).to have_been_requested
      end

    end

    describe 'validates input correctness' do

      it 'raises error when api key is absent' do
        expect { @client.search raw_name: 'first last', api_key: nil }.to raise_error ArgumentError
      end

      it 'raises error when search pointer is empty' do
        expect { @client.search search_pointer: '' }.to raise_error ArgumentError
      end

      it 'raises error when person is not searchable' do
        expect { @client.search }.to raise_error ArgumentError
        expect { @client.search person: Pipl::Person.new }.to raise_error ArgumentError
      end

      it 'raises error when minimum_probability is out of range in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, minimum_probability: 1.5
        }.to raise_error ArgumentError
      end

      it 'raises error when minimum_match is out of range in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, minimum_match: 1.5
        }.to raise_error ArgumentError
      end

      it 'raises error when show_sources has invalid value in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, show_sources: 'show_sources'
        }.to raise_error ArgumentError

        expect {
          @client.search username: 'username', strict_validation: true, show_sources: 8
        }.to raise_error ArgumentError
      end

      it 'raises error when match_requirements is not a String in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, match_requirements: true
        }.to raise_error ArgumentError
      end

      it 'raises error when source_category_requirements is not a String in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, source_category_requirements: true
        }.to raise_error ArgumentError
      end

      it 'raises error when infer_persons is not true, false or nil in strict validation' do
        expect {
          @client.search username: 'username', strict_validation: true, infer_persons: 8
        }.to raise_error ArgumentError
      end

      it 'raises error when some fields are not searchable in strict validation' do
        expect {
          @client.search username: 'username', email: 'test@example', strict_validation: true
        }.to raise_error ArgumentError
      end

    end

    describe 'handles all success codes' do

      it 'handles HTTP 204 - No Content' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(body: {:@http_status_code => 204, :@search_id => 1}.to_json,
                                 status: 204)

        response = @client.search search_pointer: 'search_pointer'
        expect(request).to have_been_requested
        expect(response).to be_instance_of(Pipl::Client::SearchResponse)
        expect(response.http_status_code).to eq(204)
        expect(response.search_id).to eq(1)
      end

    end

    describe 'handles errors' do

      it 'raises error on user mistake' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(body: {:@http_status_code => 401, error: 'API key is missing or invalid'}.to_json,
                                 status: 401)

        expect {
          @client.search search_pointer: 'search_pointer'
        }.to raise_error Pipl::Client::APIError, 'API key is missing or invalid'
        expect(request).to have_been_requested
      end

      it 'raises error on server crush' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(status: [500, 'Internal Server Error'])

        expect {
          @client.search search_pointer: 'search_pointer'
        }.to raise_error Pipl::Client::APIError, 'Internal Server Error'
        expect(request).to have_been_requested
      end

      it 'raises error on timeout' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_timeout

        expect {
          @client.search search_pointer: 'search_pointer'
        }.to raise_error Timeout::Error
        expect(request).to have_been_requested
      end

    end

    describe 'exposes quota and throttle headers' do

      it 'store values in response' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(body: {:@http_status_code => 200, :@search_id => 1}.to_json,
                                 status: 200,
                                 headers: {
                                     :'X-QPS-Allotted' => 1,
                                     :'X-QPS-Current' => 2,
                                     :'X-QPS-Live-Allotted' => 3,
                                     :'X-QPS-Live-Current' => 4,
                                     :'X-QPS-Demo-Allotted' => 5,
                                     :'X-QPS-Demo-Current' => 6,
                                     :'X-APIKey-Quota-Allotted' => 7,
                                     :'X-APIKey-Quota-Current' => 8,
                                     :'X-Quota-Reset' => 'Tuesday, September 03, 2013 07:06:05 AM UTC',
                                     :'X-Demo-Usage-Allotted' => 9,
                                     :'X-Demo-Usage-Current' => 10,
                                     :'X-Demo-Usage-Expiry' => 'Tuesday, September 03, 2013 07:06:05 AM UTC'
                                 }
                      )

        response = @client.search search_pointer: 'search_pointer'
        expect(request).to have_been_requested
        expect(response).to be_instance_of(Pipl::Client::SearchResponse)
        expect(response.http_status_code).to eq(200)
        expect(response.search_id).to eq(1)
        expect(response.qps_allotted).to eq(1)
        expect(response.qps_current).to eq(2)
        expect(response.qps_live_allotted).to eq(3)
        expect(response.qps_live_current).to eq(4)
        expect(response.qps_demo_allotted).to eq(5)
        expect(response.qps_demo_current).to eq(6)
        expect(response.quota_allotted).to eq(7)
        expect(response.quota_current).to eq(8)
        expect(response.quota_reset).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
        expect(response.demo_usage_allotted).to eq(9)
        expect(response.demo_usage_current).to eq(10)
        expect(response.demo_usage_expiry).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
      end

      it 'store values in error' do
        request = stub_post.
            with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                      .to_return(body: {:@http_status_code => 403, error: 'Per second limit reached.'}.to_json,
                                 status: 403,
                                 headers: {
                                     :'X-QPS-Allotted' => 1,
                                     :'X-QPS-Current' => 2,
                                     :'X-QPS-Live-Allotted' => 3,
                                     :'X-QPS-Live-Current' => 4,
                                     :'X-QPS-Demo-Allotted' => 5,
                                     :'X-QPS-Demo-Current' => 6,
                                     :'X-APIKey-Quota-Allotted' => 7,
                                     :'X-APIKey-Quota-Current' => 8,
                                     :'X-Quota-Reset' => 'Tuesday, September 03, 2013 07:06:05 AM UTC',
                                     :'X-Demo-Usage-Allotted' => 9,
                                     :'X-Demo-Usage-Current' => 10,
                                     :'X-Demo-Usage-Expiry' => 'Tuesday, September 03, 2013 07:06:05 AM UTC'
                                 })

        expect {
          @client.search search_pointer: 'search_pointer'
        }.to raise_error { |err|
          expect(err).to be_instance_of(Pipl::Client::APIError)
          expect(err.message).to eq('Per second limit reached.')
          expect(err.qps_allotted).to eq(1)
          expect(err.qps_current).to eq(2)
          expect(err.qps_live_allotted).to eq(3)
          expect(err.qps_live_current).to eq(4)
          expect(err.qps_demo_allotted).to eq(5)
          expect(err.qps_demo_current).to eq(6)
          expect(err.quota_allotted).to eq(7)
          expect(err.quota_current).to eq(8)
          expect(err.quota_reset).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
          expect(err.demo_usage_allotted).to eq(9)
          expect(err.demo_usage_current).to eq(10)
          expect(err.demo_usage_expiry).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
        }
        expect(request).to have_been_requested
      end

    end

  end

  describe 'when making async requests' do

    before do
      Pipl.reset!
      @client = Pipl.client
    end

    it 'uses passed block as callback' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_return(empty_json_response)

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', async: true, &b
        t.join
      }.to yield_with_args(have_key(:response))
      expect(request).to have_been_requested
    end

    it 'uses passed block as callback for errors' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_return(status: [500, 'Internal Server Error'])

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', async: true, &b
        t.join
      }.to yield_with_args(have_key(:error))
      expect(request).to have_been_requested
    end

    it 'uses passed block as callback for timeout errors' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_timeout

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', async: true, &b
        t.join
      }.to yield_with_args(have_key(:error))
      expect(request).to have_been_requested
    end

    it 'uses callback option' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_return(empty_json_response)

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', callback: Proc.new(&b)
        t.join
      }.to yield_with_args(have_key(:response))
      expect(request).to have_been_requested
    end

    it 'uses callback option for errors' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_return(status: [500, 'Internal Server Error'])

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', callback: Proc.new(&b)
        t.join
      }.to yield_with_args(have_key(:error))
      expect(request).to have_been_requested
    end

    it 'uses callback option for timeout errors' do
      request = stub_post.
          with(body: {search_pointer: 'search_pointer'}, query: {key: ENV['PIPL_API_KEY']})
                    .to_timeout

      expect { |b|
        t = @client.search search_pointer: 'search_pointer', callback: Proc.new(&b)
        t.join
      }.to yield_with_args(have_key(:error))
      expect(request).to have_been_requested
    end

  end

end
