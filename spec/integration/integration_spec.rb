require 'json'
require 'pipl'
require 'rspec'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end

describe 'integration tests' do

  it 'makes a basic search' do
    resp = Pipl::client.search first_name: 'brian', last_name: 'perks'
    expect(resp.http_status_code).to eq(200)
  end

  it 'makes a matching search' do
    resp = Pipl::client.search email: 'brianperks@gmail.com'
    expect(resp.http_status_code).to eq(200)
    expect(resp.person).not_to be_nil
  end

  it 'makes a follow up search' do
    resp = Pipl::client.search first_name: 'brian', last_name: 'perks'
    expect(resp.possible_persons).not_to be_empty
    resp = Pipl::client.search search_pointer: resp.possible_persons[0].search_pointer
    expect(resp.person).not_to be_nil
  end

  it 'makes sure we hide sponsored results on demand' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', hide_sponsored: true
    expect(resp.person.urls.any? {|x| x.sponsored}).to be_falsey
  end

  it 'makes sure we hide inferred results on demand' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', minimum_probability: 1.0
    expect(resp.person.all_fields.any? {|x| x.inferred}).to be_falsey
  end

  it 'makes sure we get inferred results' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', minimum_probability: 0.5
    expect(resp.person.all_fields.any? {|x| x.inferred}).to be_truthy
  end

  it 'makes sure we show matching sources' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', show_sources: Pipl::Configurable::SHOW_SOURCES_MATCHING
    expect(resp.sources).not_to be_empty
    expect(resp.sources.any? {|x| x.person_id != resp.person.id}).to be_falsey
  end

  it 'makes sure we show all sources' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', show_sources: Pipl::Configurable::SHOW_SOURCES_ALL
    expect(resp.sources).not_to be_empty
    expect(resp.sources.any? {|x| x.person_id != resp.person.id}).to be_truthy
  end

  it 'makes sure minimum match works' do
    resp = Pipl::client.search first_name: 'brian', last_name: 'perks', minimum_match: 0.7
    expect(resp.possible_persons.any? {|x| x.match < 0.7}).to be_falsey
  end

  it 'makes sure deserialization works' do
    resp = Pipl::client.search email: 'clark.kent@example.com'
    expect(resp.person.names[0].display).to eq ('Clark Joseph Kent')
    expect(resp.person.emails[1].address_md5).to eq ('999e509752141a0ee42ff455529c10fc')
    expect(resp.person.usernames[0].content).to eq ('superman@facebook')
    expect(resp.person.addresses[1].display).to eq ('1000-355 Broadway, Metropolis, Kansas')
    expect(resp.person.jobs[0].display).to eq ('Field Reporter at The Daily Planet (2000-2012)')
    expect(resp.person.educations[0].degree).to eq ('B.Sc Advanced Science')
  end

  it 'makes sure email md5 search works' do
    person = Pipl::Person.new
    person.add_field Pipl::Email.new address_md5: 'e34996fda036d60aa2a595ca86ed8fef'
    resp = Pipl::client.search person: person
    expect(resp.person).not_to be_nil
  end

  it 'makes sure social datatypes are available' do
    resp = Pipl::client.search email: 'brianperks@gmail.com', extra: ['developer_class=social']
    social = [Pipl::Name, Pipl::Url, Pipl::Email, Pipl::Username, Pipl::UserID, Pipl::Image]
    expect(resp.person.all_fields.all? {|x| social.include? x.class}).to be_truthy
  end

end
