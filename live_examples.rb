require_relative 'lib/pipl'

Pipl.configure do |c|
  c.api_key = 'sample_key'
  c.show_sources = 'all'
  c.strict_validation = true
end

def print_response(resp)
  if resp.key? :error
    puts "Error: #{resp[:error].message}"
  else
    puts "Success: #{resp[:response].inspect}"
  end
end

# Example for a simple call

resp = Pipl::client.search email: 'clark.kent@example.com'
puts resp.inspect



# Example for a simple call which returns an error

begin
  resp = Pipl::client.search email: 'clark.kent@example.com', api_key: 'd'
  puts resp.inspect
rescue Exception => e
  puts "Error: #{e.message}"
end



# Example for an async call with callback

t = Pipl::client.search email: 'clark.kent@example.com', callback: Proc.new { |resp| print_response resp }
t.join



# Example for an async call with a block as callback

t = Pipl::client.search email: 'clark.kent@example.com', async: true do |resp|
  print_response resp
end
t.join



# Example for an async call with a block as callback. Error (api key invalid)

t = Pipl::client.search email: 'clark.kent@example.com', api_key: 'd', async: true do |resp|
  print_response resp
end
t.join

