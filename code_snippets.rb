require_relative 'lib/pipl'


# Home page
response = Pipl::client.search email: 'clark.kent@example.com'
puts response.image.thumbnail_url width: 200, height: 100, favicon: true, zoom_face: true
puts response.name
puts response.education
puts response.username
puts response.address
puts response.person.jobs.map(&:to_s).join(', ')
puts response.person.relationships.map {|r| r.names.first}.join(', ')



# Simple request
response = Pipl::client.search email: 'clark.kent@example.com'



# Advanced request
person = Pipl::Person.new
person.add_field Pipl::Name.new(first: 'Clark', last: 'Kent')
person.add_field Pipl::Address.new(country: 'US', state: 'KS', city: 'Smallville')
person.add_field Pipl::Address.new(country: 'US', state: 'KS', city: 'Metropolis')
person.add_field Pipl::Job.new(title: 'Field Reporter')

response = Pipl::client.search person: person



# Error handling
begin
  response = Pipl::client.search email: 'clark.kent@example.com'
rescue Pipl::Client::APIError => e
  puts e.status_code, e.message
end



# Async requests

# using a block
thread = Pipl::client.search email: 'clark.kent@example.com', async: true do |resp|
  puts resp[:response] or resp[:error]
end
thread.join

# using a callback
thread = Pipl::client.search email: 'clark.kent@example.com',
                        callback: Proc.new { |resp| puts resp[:response] or resp[:error] }
thread.join



# Working with a response
response = Pipl::client.search email: 'clark.kent@example.com'
puts response.name
# Output: 'Clark Joseph Kent'
puts response.gender
# Output: 'Male'
puts response.address
# Output: '10-1 Hickory Lane, Smallville, Kansas'
puts response.job
# Output: 'Field Reporter at The Daily Planet (2000-2012)'



response = Pipl::client.search email: 'clark.kent@example.com'
puts response.person.addresses
# Output: '10-1 Hickory Lane, Smallville, Kansas'
# Output: '1000-355 Broadway, Metropolis, Kansas'



# Request with sources
response = Pipl::client.search email: 'clark.kent@example.com', show_sources: 'all'
puts response.sources[1].phones[0].display
# Output: '(978) 555-0145'
puts response.sources[1].origin_url
# Output: 'http://facebook.com/superman'



# Sources helpers
response = Pipl::client.search email: 'clark.kent@example.com', show_sources: 'all'
puts response.group_sources_by_domain['linkedin.com'].size
# Output: 1



# Field helpers
response = Pipl::client.search email: 'clark.kent@example.com'
address = response.address
puts address.state
# Output: 'KS'
puts address.state_full
# Output: 'Kansas'

email = response.email
puts email.username
# Output: 'clark.kent'



# Global configuration
Pipl.configure do |c|
  c.api_key = 'my_api_key'
  c.show_sources = 'all'
  c.minimum_probability = 0.7
  c.minimum_match = 0.5
  c.strict_validation = true
end



# Image thumbnail
image = Pipl::Image.new(thumbnail_token: 'token')
image.thumbnail_url width: 200, height: 100, favicon: true, zoom_face: true

# With a fallback image
fallback = Pipl::Image.new(thumbnail_token: 'fallback_token')
image.thumbnail_url width: 200, height: 100, favicon: true, zoom_face: true, fallback: fallback