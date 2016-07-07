require_relative '../helper'


describe Pipl::Client::APIError do

  it 'initializes with error message and status code' do
    e = Pipl::Client::APIError.new 'Bad Request', 400
    expect(e.message).to eq 'Bad Request'
    expect(e.status_code).to eq 400
  end

  it 'initializes with quota headers' do
    reset_time = DateTime.now
    e = Pipl::Client::APIError.new 'Per second limit reached.', 403, {
        qps_allotted: 1,
        qps_current: 2,
        quota_allotted: 3,
        quota_current: 4,
        quota_reset: reset_time
    }
    expect(e.message).to eq 'Per second limit reached.'
    expect(e.status_code).to eq 403
    expect(e.qps_allotted).to eq(1)
    expect(e.qps_current).to eq(2)
    expect(e.quota_allotted).to eq(3)
    expect(e.quota_current).to eq(4)
    expect(e.quota_reset).to eq(reset_time)
  end

  it 'deserialize with quota headers' do
    json_str = fixture('error.json').read
    headers = {
        'X-APIKey-QPS-Allotted' => 1,
        'X-APIKey-QPS-Current' => 2,
        'X-APIKey-Quota-Allotted' => 3,
        'X-APIKey-Quota-Current' => 4,
        'X-Quota-Reset' => 'Tuesday, September 03, 2013 07:06:05 AM UTC'
    }
    e = Pipl::Client::APIError.deserialize(json_str, headers)
    expect(e.message).to eq 'Per second limit reached.'
    expect(e.status_code).to eq 403
    expect(e.qps_allotted).to eq(1)
    expect(e.qps_current).to eq(2)
    expect(e.quota_allotted).to eq(3)
    expect(e.quota_current).to eq(4)
    expect(e.quota_reset).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
  end

  it 'creates instance from json' do
    e = Pipl::Client::APIError.from_json({error:'Bad Request', :@http_status_code => 400}.to_json)
    expect(e.message).to eq 'Bad Request'
    expect(e.status_code).to eq 400
  end

  it 'indicates user error' do
    e = Pipl::Client::APIError.new 'Bad Request', 400
    expect(e.is_user_error?).to be true
    expect(e.is_pipl_error?).to be false
  end

  it 'indicates server error' do
    e = Pipl::Client::APIError.new 'Internal Server Error', 500
    expect(e.is_pipl_error?).to be true
    expect(e.is_user_error?).to be false
  end

end

