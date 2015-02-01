require_relative 'lib/pipl'

Pipl.configure do |c|
  c.api_key = 'sample_key'
  c.show_sources = true
end

resp = Pipl::client.search email: 'clark.kent@example.com'
puts resp.inspect
# puts resp.origin_country
puts resp.person.to_hash.to_json
