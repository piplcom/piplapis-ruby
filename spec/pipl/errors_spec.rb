require_relative '../helper'


describe Pipl::Client::APIError do

  it 'initialize with error message and status code' do
    e = Pipl::Client::APIError.new 'Bad Request', 400
    expect(e.message).to eq 'Bad Request'
    expect(e.status_code).to eq 400
  end

  it 'create instance from json' do
    e = Pipl::Client::APIError.from_json({error:'Bad Request', :@http_status_code => 400}.to_json)
    expect(e.message).to eq 'Bad Request'
    expect(e.status_code).to eq 400
  end

  it 'indicate user error' do
    e = Pipl::Client::APIError.new 'Bad Request', 400
    expect(e.is_user_error?).to be true
    expect(e.is_pipl_error?).to be false
  end

  it 'indicate server error' do
    e = Pipl::Client::APIError.new 'Internal Server Error', 500
    expect(e.is_pipl_error?).to be true
    expect(e.is_user_error?).to be false
  end

end

