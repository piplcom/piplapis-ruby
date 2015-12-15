require_relative '../helper'

describe Pipl::Field do

  it 'initializes with no params' do
    field = Pipl::Field.new
    expect(field.valid_since).to be_nil
    expect(field.inferred).to be_nil
  end

  it 'initializes with params' do
    field = Pipl::Field.new valid_since: TODAY, inferred: true
    expect(field.valid_since).to eq(TODAY)
    expect(field.inferred).to be true
  end

  it 'creates instance from hash' do
    field = Pipl::Field.from_hash :@valid_since => TODAY_STR
    expect(field.valid_since).to eq(TODAY)
    expect(field.inferred).to be_nil
  end

  it 'extract base params from hash' do
    h = {:@inferred => true,
         :@type => 'type',
         :@valid_since => TODAY_STR,
         :display => 'display',
         date_range: {
             start: TODAY_STR,
             end: TODAY_STR,
         }}
    params = Pipl::Field.base_params_from_hash h
    expect(params[:inferred]).to be true
    expect(params[:type]).to eq 'type'
    expect(params[:display]).to eq 'display'
    expect(params[:valid_since]).to eq(TODAY)
  end

  it 'class has no extra metadata attributes by default' do
    expect(Pipl::Field.extra_metadata).to be_empty
  end

  it 'hash is nil by default' do
    field = Pipl::Field.new
    expect(field.to_hash).to be_nil
  end

  it 'is searchable by default' do
    field = Pipl::Field.new
    expect(field.is_searchable?).to be true
  end

end


describe Pipl::Name do

  it 'initializes with no params' do
    name = Pipl::Name.new
    expect(name.first).to be_nil
    expect(name.middle).to be_nil
    expect(name.last).to be_nil
    expect(name.prefix).to be_nil
    expect(name.suffix).to be_nil
    expect(name.type).to be_nil
    expect(name.raw).to be_nil
    expect(name.display).to be_nil
    expect(name.valid_since).to be_nil
    expect(name.inferred).to be_nil
  end

  it 'initializes with params' do
    name = Pipl::Name.new first: 'first', last: 'last', valid_since: TODAY
    expect(name.first).to eq('first')
    expect(name.last).to eq('last')
    expect(name.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    name = Pipl::Name.from_hash first: 'first', last: 'last', :@type => 'maiden',
                                :@valid_since => TODAY_STR
    expect(name.first).to eq('first')
    expect(name.last).to eq('last')
    expect(name.type).to eq('maiden')
    expect(name.valid_since).to eq(TODAY)
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {first: 'first', last: 'last'},
        {first: 'first', middle: 'middle', last: 'last'},
        {first: 'first', middle: 'middle', last: 'last', prefix: 'prefix'},
        {first: 'first', middle: 'middle', last: 'last', prefix: 'prefix', suffix: 'suffix'},
        {first: 'first', middle: 'middle', last: 'last', prefix: 'prefix', suffix: 'suffix', raw: 'raw'}
    ].each do |params|
      name = Pipl::Name.new params
      expect(name.to_hash).to eq(params)
    end
  end

  it 'is searchable with raw name' do
    name = Pipl::Name.new raw: 'first middle last'
    expect(name.is_searchable?).to be true
  end

  it 'is searchable with first and last names' do
    name = Pipl::Name.new first: 'first', last: 'last'
    expect(name.is_searchable?).to be true
  end

  it 'is not searchable without raw name or first and last names' do
    name = Pipl::Name.new first: 'first'
    expect(name.is_searchable?).to be false
    name = Pipl::Name.new last: 'last'
    expect(name.is_searchable?).to be false
    name = Pipl::Name.new first: 'f', last: 'last'
    expect(name.is_searchable?).to be false
    name = Pipl::Name.new first: 'first', last: 'l'
    expect(name.is_searchable?).to be false
  end

  it 'string show display if available' do
    name = Pipl::Name.new first: 'first', last: 'last', display: 'display'
    expect(name.to_s).to eq 'display'
  end

  it 'string is human when display is not available' do
    name = Pipl::Name.new first: 'first', last: 'last', prefix: 'mr'
    expect(name.to_s).to eq 'Mr First Last'
  end

end


describe Pipl::Address do

  it 'initializes with no params' do
    address = Pipl::Address.new
    expect(address.country).to be_nil
    expect(address.state).to be_nil
    expect(address.city).to be_nil
    expect(address.street).to be_nil
    expect(address.house).to be_nil
    expect(address.apartment).to be_nil
    expect(address.zip_code).to be_nil
    expect(address.po_box).to be_nil
    expect(address.raw).to be_nil
    expect(address.display).to be_nil
    expect(address.valid_since).to be_nil
    expect(address.inferred).to be_nil
  end

  it 'initializes with params' do
    address = Pipl::Address.new country: 'US', state: 'AZ', valid_since: TODAY
    expect(address.country).to eq('US')
    expect(address.state).to eq('AZ')
    expect(address.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    address = Pipl::Address.from_hash country: 'US', state: 'AZ', :@type => 'work',
                                      :@valid_since => TODAY_STR
    expect(address.country).to eq('US')
    expect(address.state).to eq('AZ')
    expect(address.type).to eq('work')
    expect(address.valid_since).to eq(TODAY)
  end

  it 'indicate if country is valid or not' do
    address = Pipl::Address.from_hash country: 'US'
    expect(address.is_valid_country?).to be true
    address = Pipl::Address.from_hash country: '__'
    expect(address.is_valid_country?).to be false
  end

  it 'indicate if state is valid or not' do
    address = Pipl::Address.from_hash country: 'US', state: 'AZ'
    expect(address.is_valid_state?).to be true
    address = Pipl::Address.from_hash country: 'US', state: '__'
    expect(address.is_valid_state?).to be false
    address = Pipl::Address.from_hash country: 'GB', state: 'AZ'
    expect(address.is_valid_state?).to be false
    address = Pipl::Address.from_hash country: 'FR', state: 'AZ'
    expect(address.is_valid_state?).to be false
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {country: 'country'},
        {country: 'country', state: 'state'},
        {country: 'country', state: 'state', city: 'city'},
        {country: 'country', state: 'state', city: 'city', street: 'street'},
        {country: 'country', state: 'state', city: 'city', street: 'street', house: 'house'},
        {country: 'country', state: 'state', city: 'city', street: 'street', house: 'house', apartment: 'apartment'},
        {country: 'country', state: 'state', city: 'city', street: 'street', house: 'house', apartment: 'apartment',
         zip_code: 'zip_code'},
        {country: 'country', state: 'state', city: 'city', street: 'street', house: 'house', apartment: 'apartment',
         zip_code: 'zip_code', po_box: 'po_box'},
        {country: 'country', state: 'state', city: 'city', street: 'street', house: 'house', apartment: 'apartment',
         zip_code: 'zip_code', po_box: 'po_box', raw: 'raw'}
    ].each do |params|
      address = Pipl::Address.new params
      expect(address.to_hash).to eq(params)
    end
  end

  it 'is searchable with raw address' do
    address = Pipl::Address.new raw: 'somewhere in Arizona, US'
    expect(address.is_searchable?).to be true
  end

  it 'is searchable with a country' do
    address = Pipl::Address.new country: 'US'
    expect(address.is_searchable?).to be true
  end

  it 'is searchable with a state' do
    address = Pipl::Address.new state: 'AZ'
    expect(address.is_searchable?).to be true
  end


  it 'is searchable with a city' do
    address = Pipl::Address.new city: 'New York'
    expect(address.is_searchable?).to be true
  end

  it 'is not searchable without raw address or country or state or city' do
    address = Pipl::Address.new street: '__'
    expect(address.is_searchable?).to be false
    address = Pipl::Address.new house: '4'
    expect(address.is_searchable?).to be false
  end

  it 'show full country name' do
    address = Pipl::Address.new country: 'US'
    expect(address.country_full).to eq('United States')
  end

  it 'show full state name' do
    address = Pipl::Address.new country: 'US', state: 'AZ'
    expect(address.state_full).to eq('Arizona')
  end

  it 'string show display if available' do
    address = Pipl::Address.new country: 'US', state: 'AZ', display: 'display'
    expect(address.to_s).to eq 'display'
  end

  it 'string is human when display is not available' do
    address = Pipl::Address.new country: 'US', state: 'AZ'
    expect(address.to_s).to eq 'Arizona, US'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix', street: 'some street', house: '19'
    expect(address.to_s).to eq '19 some street, Phoenix, AZ, US'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix', po_box: '1023'
    expect(address.to_s).to eq 'P.O. Box 1023 Phoenix, AZ, US'
  end

end


describe Pipl::Phone do

  it 'initializes with no params' do
    phone = Pipl::Phone.new
    expect(phone.number).to be_nil
    expect(phone.country_code).to be_nil
    expect(phone.extension).to be_nil
    expect(phone.type).to be_nil
    expect(phone.raw).to be_nil
    expect(phone.display).to be_nil
    expect(phone.display_international).to be_nil
    expect(phone.valid_since).to be_nil
    expect(phone.inferred).to be_nil
  end

  it 'initializes with params' do
    phone = Pipl::Phone.new number: 2123334444, country_code: 1, valid_since: TODAY
    expect(phone.number).to eq(2123334444)
    expect(phone.country_code).to eq(1)
    expect(phone.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    phone = Pipl::Phone.from_hash number: 2123334444, country_code: 1, :@type => 'home_phone',
                                  :@valid_since => TODAY_STR
    expect(phone.number).to eq(2123334444)
    expect(phone.country_code).to eq(1)
    expect(phone.type).to eq('home_phone')
    expect(phone.valid_since).to eq(TODAY)
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {country_code: 'country_code'},
        {country_code: 'country_code', number: 'number'},
        {country_code: 'country_code', number: 'number', extension: 'extension'},
        {country_code: 'country_code', number: 'number', extension: 'extension', raw: 'raw'}
    ].each do |params|
      phone = Pipl::Phone.new params
      expect(phone.to_hash).to eq(params)
    end
  end

  it 'is searchable with raw phone' do
    phone = Pipl::Phone.new raw: '+44 123456789'
    expect(phone.is_searchable?).to be true
  end

  it 'is searchable with number' do
    phone = Pipl::Phone.new number: 2123334444
    expect(phone.is_searchable?).to be true
  end

  it 'is not searchable without raw phone or number' do
    phone = Pipl::Phone.new country_code: 1
    expect(phone.is_searchable?).to be false
    phone = Pipl::Phone.new country_code: 1, extension: 'x123'
    expect(phone.is_searchable?).to be false
  end

  # it 'string show display if available' do
  #   phone = Pipl::Phone.new number: 2123334444, display: 'display'
  #   expect(phone.to_s).to eq 'display'
  # end
  #
  # it 'string is human when display is not available' do
  #   phone = Pipl::Phone.new number: 2123334444
  #   expect(phone.to_s).to eq '2123334444'
  # end

end


describe Pipl::Email do

  it 'initializes with no params' do
    email = Pipl::Email.new
    expect(email.address).to be_nil
    expect(email.address_md5).to be_nil
    expect(email.type).to be_nil
    expect(email.disposable).to be_nil
    expect(email.email_provider).to be_nil
    expect(email.valid_since).to be_nil
    expect(email.inferred).to be_nil
  end

  it 'initializes with params' do
    email = Pipl::Email.new address: 'test@example.com', valid_since: TODAY
    expect(email.address).to eq('test@example.com')
    expect(email.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    email = Pipl::Email.from_hash address: 'test@example.com', address_md5: '55502f40dc8b7c769880b10874abc9d0',
                                  :@type => 'work', :@valid_since => TODAY_STR
    expect(email.address).to eq('test@example.com')
    expect(email.address_md5).to eq('55502f40dc8b7c769880b10874abc9d0')
    expect(email.type).to eq('work')
    expect(email.valid_since).to eq(TODAY)
  end

  it 'has extra metadata' do
    expect(Pipl::Email.extra_metadata).to contain_exactly :disposable, :email_provider
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {address: 'address'},
        {address: 'address', address_md5: 'address_md5'}
    ].each do |params|
      email = Pipl::Email.new params
      expect(email.to_hash).to eq(params)
    end
  end

  it 'is searchable with valid address' do
    email = Pipl::Email.new address: 'test@example.com'
    expect(email.is_searchable?).to be true
  end

  it 'is searchable with valid address MD5' do
    email = Pipl::Email.new address_md5: '55502f40dc8b7c769880b10874abc9d0'
    expect(email.is_searchable?).to be true
  end

  it 'is not searchable without valid address or address MD5' do
    email = Pipl::Email.new
    expect(email.is_searchable?).to be false
    email = Pipl::Email.new address: 'test@example'
    expect(email.is_searchable?).to be false
    email = Pipl::Email.new address_md5: 'invalid_md5'
    expect(email.is_searchable?).to be false
  end

  it 'indicate valid email address' do
    email = Pipl::Email.new address: 'test@example.com'
    expect(email.is_valid_email?).to be true
    email = Pipl::Email.new address: 'test@example'
    expect(email.is_valid_email?).to be false
  end

  it 'extract username part' do
    email = Pipl::Email.new address: 'test@example.com'
    expect(email.username).to eq('test')
  end

  it 'extract domain part' do
    email = Pipl::Email.new address: 'test@example.com'
    expect(email.domain).to eq('example.com')
  end

end


describe Pipl::Job do

  it 'initializes with no params' do
    job = Pipl::Job.new
    expect(job.title).to be_nil
    expect(job.organization).to be_nil
    expect(job.industry).to be_nil
    expect(job.date_range).to be_nil
    expect(job.display).to be_nil
    expect(job.valid_since).to be_nil
    expect(job.inferred).to be_nil
  end

  it 'initializes with params' do
    job = Pipl::Job.new title: 'title', valid_since: TODAY
    expect(job.title).to eq('title')
    expect(job.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    job = Pipl::Job.from_hash title: 'title', organization: 'organization',
                              :@valid_since => TODAY_STR
    expect(job.title).to eq('title')
    expect(job.organization).to eq('organization')
    expect(job.valid_since).to eq(TODAY)
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {title: 'title'},
        {title: 'title', organization: 'organization'},
        {title: 'title', organization: 'organization', industry: 'industry'},
        {title: 'title', organization: 'organization', industry: 'industry', date_range: {start: TODAY, end: TODAY,}}
    ].each do |params|
      job = Pipl::Job.new params
      expect(job.to_hash).to eq(params)
    end
  end

  it 'string show display if available' do
    job = Pipl::Job.new title: 'title', organization: 'organization', display: 'display'
    expect(job.to_s).to eq 'display'
  end

  it 'string is human when display is not available' do
    job = Pipl::Job.new title: 'title'
    expect(job.to_s).to eq 'title'
    job = Pipl::Job.new organization: 'organization'
    expect(job.to_s).to eq 'organization'
    job = Pipl::Job.new title: 'title', organization: 'organization'
    expect(job.to_s).to eq 'title at organization'
    job = Pipl::Job.new title: 'title', organization: 'organization', date_range: Pipl::DateRange.new(TODAY - 365, TODAY)
    expect(job.to_s).to eq "title at organization (#{TODAY.year - 1}-#{TODAY.year})"
  end

end


describe Pipl::Education do

  it 'initializes with no params' do
    education = Pipl::Education.new
    expect(education.degree).to be_nil
    expect(education.school).to be_nil
    expect(education.date_range).to be_nil
    expect(education.display).to be_nil
    expect(education.valid_since).to be_nil
    expect(education.inferred).to be_nil
  end

  it 'initializes with params' do
    education = Pipl::Education.new school: 'school', valid_since: TODAY
    expect(education.school).to eq('school')
    expect(education.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    education = Pipl::Education.from_hash school: 'school', degree: 'degree', :@valid_since => TODAY_STR
    expect(education.school).to eq('school')
    expect(education.degree).to eq('degree')
    expect(education.valid_since).to eq(TODAY)
  end

  it 'hash contain all searchable parts and is compact' do
    [
        {},
        {school: 'school'},
        {school: 'school', degree: 'degree'},
        {school: 'school', degree: 'degree', date_range: {start: TODAY, end: TODAY,}}
    ].each do |params|
      education = Pipl::Education.new params
      expect(education.to_hash).to eq(params)
    end
  end

  it 'string show display if available' do
    education = Pipl::Education.new school: 'school', degree: 'degree', display: 'display'
    expect(education.to_s).to eq 'display'
  end

  it 'string is human when display is not available' do
    education = Pipl::Education.new school: 'school'
    expect(education.to_s).to eq 'school'
    education = Pipl::Education.new degree: 'degree'
    expect(education.to_s).to eq 'degree'
    education = Pipl::Education.new school: 'school', degree: 'degree'
    expect(education.to_s).to eq 'degree from school'
    education = Pipl::Education.new school: 'school', degree: 'degree',
                                    date_range: Pipl::DateRange.new(TODAY - 365, TODAY)
    expect(education.to_s).to eq "degree from school (#{TODAY.year - 1}-#{TODAY.year})"
  end

end


describe Pipl::Image do

  it 'initializes with no params' do
    image = Pipl::Image.new
    expect(image.url).to be_nil
    expect(image.thumbnail_token).to be_nil
    expect(image.valid_since).to be_nil
    expect(image.inferred).to be_nil
  end

  it 'initializes with params' do
    image = Pipl::Image.new url: 'url', valid_since: TODAY
    expect(image.url).to eq('url')
    expect(image.valid_since).to eq(TODAY)
  end

  it 'creates instance from hash' do
    image = Pipl::Image.from_hash url: 'url', thumbnail_token: 'thumbnail_token', :@valid_since => TODAY_STR
    expect(image.url).to eq('url')
    expect(image.thumbnail_token).to eq('thumbnail_token')
    expect(image.valid_since).to eq(TODAY)
  end

  it 'constructs a thumbnail url with no params' do
    image = Pipl::Image.from_hash thumbnail_token: 'thumbnail_token'
    expect(image.thumbnail_url).to eq('http://thumb.pipl.com/image?token=thumbnail_token&width=100&height=100&favicon=true&zoom_face=true')
  end

  it 'constructs a HTTPS thumbnail url' do
    image = Pipl::Image.from_hash thumbnail_token: 'thumbnail_token'
    expect(image.thumbnail_url(use_https: true)).to eq('https://thumb.pipl.com/image?token=thumbnail_token&width=100&height=100&favicon=true&zoom_face=true')
  end

  it 'constructs a thumbnail url with given dimensions' do
    image = Pipl::Image.from_hash thumbnail_token: 'thumbnail_token'
    expect(image.thumbnail_url(width: 120, height:90)).to eq('http://thumb.pipl.com/image?token=thumbnail_token&width=120&height=90&favicon=true&zoom_face=true')
  end

  it 'constructs a thumbnail url without enhancments' do
    image = Pipl::Image.from_hash thumbnail_token: 'thumbnail_token'
    expect(image.thumbnail_url(favicon: false, zoom_face:false)).to eq('http://thumb.pipl.com/image?token=thumbnail_token&width=100&height=100&favicon=false&zoom_face=false')
  end

end


describe Pipl::DateRange do
  it 'should calculate middle when there is both an end and a start' do
    date_range = Pipl::DateRange.new Date.new(2001,2,3), Date.new(2010,2,3)
    expect(date_range.middle.to_datetime).to eq(Date.new(2005, 8, 4).to_datetime)
  end

  it 'should serialize to deserialized hash' do
    date_hash = {:start => '2013-11-10', :end => '2015-11-10'}
    date_range = Pipl::DateRange.from_hash date_hash
    new_hash = date_range.to_hash
    expect(new_hash).to eq date_hash
  end

  it 'should allow partial hash' do
    date_range = Pipl::DateRange.from_hash start: '2013-11-10'
    new_hash = date_range.to_hash
    expect(new_hash).to eq start: '2013-11-10'

    date_range = Pipl::DateRange.from_hash end: '2013-11-10'
    new_hash = date_range.to_hash
    expect(new_hash).to eq end: '2013-11-10'
  end

  it 'partial data range should not be exact' do
    date_range = Pipl::DateRange.from_hash end: '2013-11-10'
    expect(date_range.is_exact?).to_not be_truthy
  end
end


describe Pipl::DOB do
  it 'should should return age twice for partial data ranges' do
    range = Pipl::DateRange.new Date.new(2001,2,3), nil
    dob = Pipl::DOB.new({date_range: range})
    expect([dob.age, dob.age] == dob.age_range).to be_truthy
  end
end