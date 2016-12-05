require_relative '../helper'


describe Pipl::Client::APIError do

  it 'initializes with error message and status code' do
    e = Pipl::Client::APIError.new 'Bad Request', 400
    expect(e.message).to eq 'Bad Request'
    expect(e.status_code).to eq 400
    expect(e.qps_allotted).to be_nil
    expect(e.qps_current).to be_nil
    expect(e.qps_live_allotted).to be_nil
    expect(e.qps_live_current).to be_nil
    expect(e.qps_demo_allotted).to be_nil
    expect(e.qps_demo_current).to be_nil
    expect(e.quota_allotted).to be_nil
    expect(e.quota_current).to be_nil
    expect(e.quota_reset).to be_nil
    expect(e.demo_usage_allotted).to be_nil
    expect(e.demo_usage_current).to be_nil
    expect(e.demo_usage_expiry).to be_nil
  end

  it 'initializes with quota headers' do
    reset_time = DateTime.now
    e = Pipl::Client::APIError.new 'Per second limit reached.', 403, {
        qps_allotted: 1,
        qps_current: 2,
        qps_live_allotted: 3,
        qps_live_current: 4,
        qps_demo_allotted: 5,
        qps_demo_current: 6,
        quota_allotted: 7,
        quota_current: 8,
        quota_reset: reset_time,
        demo_usage_allotted: 9,
        demo_usage_current: 10,
        demo_usage_expiry: reset_time
    }
    expect(e.message).to eq 'Per second limit reached.'
    expect(e.status_code).to eq 403
    expect(e.qps_allotted).to eq(1)
    expect(e.qps_current).to eq(2)
    expect(e.qps_live_allotted).to eq(3)
    expect(e.qps_live_current).to eq(4)
    expect(e.qps_demo_allotted).to eq(5)
    expect(e.qps_demo_current).to eq(6)
    expect(e.quota_allotted).to eq(7)
    expect(e.quota_current).to eq(8)
    expect(e.quota_reset).to eq(reset_time)
    expect(e.demo_usage_allotted).to eq(9)
    expect(e.demo_usage_current).to eq(10)
    expect(e.demo_usage_expiry).to eq(reset_time)
  end

  it 'deserialize with quota headers' do
    json_str = fixture('error.json').read
    headers = {
        'X-QPS-Allotted' => 1,
        'X-QPS-Current' => 2,
        'X-QPS-Live-Allotted' => 3,
        'X-QPS-Live-Current' => 4,
        'X-QPS-Demo-Allotted' => 5,
        'X-QPS-Demo-Current' => 6,
        'X-APIKey-Quota-Allotted' => 7,
        'X-APIKey-Quota-Current' => 8,
        'X-Quota-Reset' => 'Tuesday, September 03, 2013 07:06:05 AM UTC',
        'X-Demo-Usage-Allotted' => 9,
        'X-Demo-Usage-Current' => 10,
        'X-Demo-Usage-Expiry' => 'Tuesday, September 03, 2013 07:06:05 AM UTC'
    }
    e = Pipl::Client::APIError.deserialize(json_str, headers)
    expect(e.message).to eq 'Per second limit reached.'
    expect(e.status_code).to eq 403
    expect(e.qps_allotted).to eq(1)
    expect(e.qps_current).to eq(2)
    expect(e.qps_live_allotted).to eq(3)
    expect(e.qps_live_current).to eq(4)
    expect(e.qps_demo_allotted).to eq(5)
    expect(e.qps_demo_current).to eq(6)
    expect(e.quota_allotted).to eq(7)
    expect(e.quota_current).to eq(8)
    expect(e.quota_reset).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
    expect(e.demo_usage_allotted).to eq(9)
    expect(e.demo_usage_current).to eq(10)
    expect(e.demo_usage_expiry).to eq(DateTime.strptime('Tuesday, September 03, 2013 07:06:05 AM UTC', '%A, %B %d, %Y %I:%M:%S %p %Z'))
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

