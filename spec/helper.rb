if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  require 'simplecov-rcov'
  # require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::RcovFormatter
  ]
  SimpleCov.start
end

require 'json'
require 'pipl'
require 'rspec'
require 'webmock/rspec'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end

ENV['PIPL_API_KEY'] = ENV.fetch 'PIPL_API_KEY', 'test_api_key'

TODAY = Date.today
TODAY_STR = TODAY.strftime(Pipl::DATE_FORMAT)

def stub_post(url = '/')
  stub_request(:post, Pipl.api_endpoint)
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

def json_response(file)
  {
      body: fixture(file),
      headers: {content_type: 'application/json; charset=utf-8'}
  }
end

def empty_json_response
  {
      body: '{}',
      headers: {content_type: 'application/json; charset=utf-8'}
  }
end
