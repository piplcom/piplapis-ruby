require_relative 'lib/pipl'

def test_request
  puts "searching..."
  # work_emails, personal_emails, vehicles
#   response = Pipl::client.search email: 'garth.moulton@pipl.com' , api_key: 'tif7qpbklu2n3qhwpf8p64rk'
#     puts "available_data: " + response.available_data.inspect

  # voip_phones
  # response = Pipl::client.search phone: '1 606-930-9577' , email: 'ampreat@gmail.com', api_key: 'tif7qpbklu2n3qhwpf8p64rk', api_version: 5.0
    # puts "available_data: " + response.person.phones.inspect
    # puts "available_data: " + response.available_data.inspect

    #vin
    response = Pipl::client.search vin: '1FTWW31R98ED96001' , api_key: 'tif7qpbklu2n3qhwpf8p64rk', show_sources: 'matching'
    puts "vehicles: " + response.person.vehicles.inspect
    # puts "vehicles: " + response.sources.inspect

    # invalid
    # response = Pipl::client.search email: '1FTWW31R98ED96001' , api_key: 'tif7qpbklu2n3qhwpf8p64rk'
end

test_request()