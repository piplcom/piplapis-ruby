require_relative '../helper'

describe Pipl::FieldsContainer do

  it 'initializes with no params' do
    container = Pipl::FieldsContainer.new
    expect(container.names).to be_empty
    expect(container.addresses).to be_empty
    expect(container.phones).to be_empty
    expect(container.emails).to be_empty
    expect(container.jobs).to be_empty
    expect(container.educations).to be_empty
    expect(container.images).to be_empty
    expect(container.usernames).to be_empty
    expect(container.user_ids).to be_empty
    expect(container.urls).to be_empty
    expect(container.ethnicities).to be_empty
    expect(container.languages).to be_empty
    expect(container.origin_countries).to be_empty
    expect(container.relationships).to be_empty
    expect(container.dob).to be_nil
    expect(container.gender).to be_nil
  end

  it 'initializes with params' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    email = Pipl::Email.new address: 'test@example.com'
    job = Pipl::Job.new title: 'title', organization: 'organization'
    education = Pipl::Education.new school: 'school', degree: 'degree'
    image = Pipl::Image.new url: 'http://www.example.com/test.jpg'
    username = Pipl::Username.new content: 'username@service'
    user_id = Pipl::UserID.new content: '654/54/12'
    url = Pipl::Url.new url: 'http://www.example.com/related/url'
    ethnicity = Pipl::Ethnicity.new content: 'korean'
    language = Pipl::Language.new language: 'en', region: 'US'
    origin_country = Pipl::OriginCountry.new country: 'KR'
    relationship = Pipl::Relationship.new fields: [Pipl::Name.new(first: 'second', last: 'last')]
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)
    gender = Pipl::Gender.new content: 'male'

    params = {fields: [name, address, phone, email, job, education, image, username, user_id, url, ethnicity, language,
                       origin_country, relationship, dob, gender]}

    container = Pipl::FieldsContainer.new params
    expect(container.names).to contain_exactly(name)
    expect(container.addresses).to contain_exactly(address)
    expect(container.phones).to contain_exactly(phone)
    expect(container.emails).to contain_exactly(email)
    expect(container.jobs).to contain_exactly(job)
    expect(container.educations).to contain_exactly(education)
    expect(container.images).to contain_exactly(image)
    expect(container.usernames).to contain_exactly(username)
    expect(container.user_ids).to contain_exactly(user_id)
    expect(container.urls).to contain_exactly(url)
    expect(container.ethnicities).to contain_exactly(ethnicity)
    expect(container.languages).to contain_exactly(language)
    expect(container.origin_countries).to contain_exactly(origin_country)
    expect(container.relationships).to contain_exactly(relationship)
    expect(container.dob).to be(dob)
    expect(container.gender).to be(gender)
  end

  it 'raises error when trying to create an instance from hash' do
    expect { Pipl::FieldsContainer.from_hash({}) }.to raise_error Pipl::AbstractMethodInvoked
  end

  it 'extracts fields from hash' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)
    gender = Pipl::Gender.new content: 'male'

    h = {
        names: [name.to_hash],
        addresses: [address.to_hash],
        phones: [phone.to_hash],
        dob: dob.to_hash,
        gender: gender.to_hash
    }

    fields = Pipl::FieldsContainer.fields_from_hash h
    expect(fields.map(&:to_hash)).to contain_exactly(*([name, address, phone, dob, gender].map(&:to_hash)))
  end

  it 'exports fields to hash' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)
    gender = Pipl::Gender.new content: 'male'

    container = Pipl::FieldsContainer.new fields: [name, address, phone, dob, gender]
    h = container.fields_to_hash

    expect(h[:names]).to contain_exactly(name.to_hash)
    expect(h[:addresses]).to contain_exactly(address.to_hash)
    expect(h[:phones]).to contain_exactly(phone.to_hash)
    expect(h[:dob]).to eq(dob.to_hash)
    expect(h[:gender]).to eq(gender.to_hash)
  end

  it 'raises error when adding unknown field' do
    container = Pipl::FieldsContainer.new
    expect{ container.add_field 1 }.to raise_error ArgumentError
  end

  it 'provides shorthand to first job' do
    container = Pipl::FieldsContainer.new
    expect(container.job).to be_nil
    job1 = Pipl::Job.new title: 'title1', organization: 'organization1'
    job2 = Pipl::Job.new title: 'title2', organization: 'organization2'
    container.jobs.push job1, job2
    expect(container.job).to be(job1)
  end

  it 'provides shorthand to first address' do
    container = Pipl::FieldsContainer.new
    expect(container.address).to be_nil
    address1 = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    address2 = Pipl::Address.new country: 'US', state: 'AZ', city: 'Tucson'
    container.addresses.push address1, address2
    expect(container.address).to be(address1)
  end

  it 'provides shorthand to first education' do
    container = Pipl::FieldsContainer.new
    expect(container.education).to be_nil
    education1 = Pipl::Education.new school: 'school1', degree: 'degree1'
    education2 = Pipl::Education.new school: 'school2', degree: 'degree2'
    container.educations.push education1, education2
    expect(container.education).to be(education1)
  end

  it 'provides shorthand to first language' do
    container = Pipl::FieldsContainer.new
    expect(container.language).to be_nil
    language1 = Pipl::Language.new language: 'en', region: 'US'
    language2 = Pipl::Language.new language: 'en', region: 'GB'
    container.languages.push language1, language2
    expect(container.language).to be(language1)
  end

  it 'provides shorthand to first ethnicity' do
    container = Pipl::FieldsContainer.new
    expect(container.ethnicity).to be_nil
    ethnicity1 = Pipl::Ethnicity.new content: 'korean'
    ethnicity2 = Pipl::Ethnicity.new content: 'white'
    container.ethnicities.push ethnicity1, ethnicity2
    expect(container.ethnicity).to be(ethnicity1)
  end

  it 'provides shorthand to first origin_country' do
    container = Pipl::FieldsContainer.new
    expect(container.origin_country).to be_nil
    origin_country1 = Pipl::OriginCountry.new country: 'KR'
    origin_country2 = Pipl::OriginCountry.new country: 'US'
    container.origin_countries.push origin_country1, origin_country2
    expect(container.origin_country).to be(origin_country1)
  end

  it 'provides shorthand to first phone' do
    container = Pipl::FieldsContainer.new
    expect(container.phone).to be_nil
    phone1 = Pipl::Phone.new number: 2123334444, country_code: 1
    phone2 = Pipl::Phone.new number: 2123334567, country_code: 1
    container.phones.push phone1, phone2
    expect(container.phone).to be(phone1)
  end

  it 'provides shorthand to first email' do
    container = Pipl::FieldsContainer.new
    expect(container.email).to be_nil
    email1 = Pipl::Email.new address: 'test1@example.com'
    email2 = Pipl::Email.new address: 'test2@example.com'
    container.emails.push email1, email2
    expect(container.email).to be(email1)
  end

end

describe Pipl::Relationship do

  it 'initializes with no params' do
    relationship = Pipl::Relationship.new
    expect(relationship.type).to be_nil
    expect(relationship.subtype).to be_nil
    expect(relationship.valid_since).to be_nil
    expect(relationship.inferred).to be_nil
    expect(relationship.names).to be_empty
    expect(relationship.addresses).to be_empty
    expect(relationship.phones).to be_empty
    expect(relationship.dob).to be_nil
  end

  it 'initializes with params' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    params = {fields: [name, address, phone, dob], type: 'family', subtype: 'subtype', valid_since: TODAY}

    relationship = Pipl::Relationship.new params
    expect(relationship.type).to eq('family')
    expect(relationship.subtype).to eq('subtype')
    expect(relationship.inferred).to be_nil
    expect(relationship.valid_since).to eq(TODAY)
    expect(relationship.names).to contain_exactly(name)
    expect(relationship.addresses).to contain_exactly(address)
    expect(relationship.phones).to contain_exactly(phone)
    expect(relationship.dob).to be(dob)
  end

  it 'creates instance from hash' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    h = {
        :@type => 'family',
        :@subtype => 'subtype',
        :@valid_since => TODAY_STR,
        names: [name.to_hash],
        addresses: [address.to_hash],
        phones: [phone.to_hash],
        dob: dob.to_hash,
    }

    relationship = Pipl::Relationship.from_hash h
    expect(relationship.type).to eq('family')
    expect(relationship.subtype).to eq('subtype')
    expect(relationship.inferred).to be_nil
    expect(relationship.valid_since).to eq(TODAY)
    expect(relationship.names.map(&:to_hash)).to contain_exactly(name.to_hash)
    expect(relationship.addresses.map(&:to_hash)).to contain_exactly(address.to_hash)
    expect(relationship.phones.map(&:to_hash)).to contain_exactly(phone.to_hash)
    expect(relationship.dob.to_hash).to eq(dob.to_hash)
  end

  it 'hash contain all searchable parts and is compact' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    relationship = Pipl::Relationship.new fields: [name, address, phone, dob]
    h = relationship.to_hash

    expect(h[:names]).to contain_exactly(name.to_hash)
    expect(h[:addresses]).to contain_exactly(address.to_hash)
    expect(h[:phones]).to contain_exactly(phone.to_hash)
    expect(h[:dob]).to eq(dob.to_hash)
  end

end


describe Pipl::Source do

  it 'initializes with no params' do
    source = Pipl::Source.new
    expect(source.name).to be_nil
    expect(source.category).to be_nil
    expect(source.origin_url).to be_nil
    expect(source.domain).to be_nil
    expect(source.source_id).to be_nil
    expect(source.person_id).to be_nil
    expect(source.sponsored).to be_nil
    expect(source.premium).to be_nil
    expect(source.match).to be_nil
    expect(source.valid_since).to be_nil
    expect(source.names).to be_empty
    expect(source.addresses).to be_empty
    expect(source.phones).to be_empty
    expect(source.dob).to be_nil
  end

  it 'initializes with params' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    params = {fields: [name, address, phone, dob], name: 'name', category: 'category', origin_url: 'origin_url',
              domain: 'domain', source_id: 'source_id', person_id: 'person_id', sponsored: true, premium: false,
              match: 0.98, valid_since: TODAY}

    source = Pipl::Source.new params
    expect(source.name).to eq('name')
    expect(source.category).to eq('category')
    expect(source.origin_url).to eq('origin_url')
    expect(source.domain).to eq('domain')
    expect(source.source_id).to eq('source_id')
    expect(source.person_id).to eq('person_id')
    expect(source.sponsored).to be true
    expect(source.premium).to be false
    expect(source.match).to eq(0.98)
    expect(source.valid_since).to eq(TODAY)
    expect(source.names).to contain_exactly(name)
    expect(source.addresses).to contain_exactly(address)
    expect(source.phones).to contain_exactly(phone)
    expect(source.dob).to be(dob)
  end

  it 'creates instance from hash' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    h = {
        :@name => 'name',
        :@category => 'category',
        :@origin_url => 'origin_url',
        :@domain => 'domain',
        :@id => 'source_id',
        :@person_id => 'person_id',
        :@sponsored => true,
        :@premium => false,
        :@match => 0.98,
        :@valid_since => TODAY_STR,
        names: [name.to_hash],
        addresses: [address.to_hash],
        phones: [phone.to_hash],
        dob: dob.to_hash,
    }

    source = Pipl::Source.from_hash h
    expect(source.name).to eq('name')
    expect(source.category).to eq('category')
    expect(source.origin_url).to eq('origin_url')
    expect(source.domain).to eq('domain')
    expect(source.source_id).to eq('source_id')
    expect(source.person_id).to eq('person_id')
    expect(source.sponsored).to be true
    expect(source.premium).to be false
    expect(source.match).to eq(0.98)
    expect(source.valid_since).to eq(TODAY)
    expect(source.names.map(&:to_hash)).to contain_exactly(name.to_hash)
    expect(source.addresses.map(&:to_hash)).to contain_exactly(address.to_hash)
    expect(source.phones.map(&:to_hash)).to contain_exactly(phone.to_hash)
    expect(source.dob.to_hash).to eq(dob.to_hash)
  end

end


describe Pipl::Person do

  it 'initializes with no params' do
    person = Pipl::Person.new
    expect(person.id).to be_nil
    expect(person.match).to be_nil
    expect(person.search_pointer).to be_nil
    expect(person.inferred).to be(false)
    expect(person.names).to be_empty
    expect(person.addresses).to be_empty
    expect(person.phones).to be_empty
    expect(person.dob).to be_nil
  end

  it 'initializes with params' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    params = {id: 'id',
              match: 0.98,
              search_pointer: 'search_pointer',
              inferred: true,
              fields: [name, address, phone, dob]}

    person = Pipl::Person.new params
    expect(person.id).to eq('id')
    expect(person.match).to eq(0.98)
    expect(person.search_pointer).to eq('search_pointer')
    expect(person.inferred).to be(true)
    expect(person.names).to contain_exactly(name)
    expect(person.addresses).to contain_exactly(address)
    expect(person.phones).to contain_exactly(phone)
    expect(person.dob).to be(dob)
  end

  it 'creates instance from hash' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    h = {
        :@id => 'id',
        :@match => 0.98,
        :@search_pointer => 'search_pointer',
        :@inferred => true,
        names: [name.to_hash],
        addresses: [address.to_hash],
        phones: [phone.to_hash],
        dob: dob.to_hash,
    }

    person = Pipl::Person.from_hash h
    expect(person.id).to eq('id')
    expect(person.match).to eq(0.98)
    expect(person.search_pointer).to eq('search_pointer')
    expect(person.names.map(&:to_hash)).to contain_exactly(name.to_hash)
    expect(person.addresses.map(&:to_hash)).to contain_exactly(address.to_hash)
    expect(person.phones.map(&:to_hash)).to contain_exactly(phone.to_hash)
    expect(person.dob.to_hash).to eq(dob.to_hash)
    expect(person.inferred).to be(true)
  end

  it 'hash contain all searchable parts and is compact' do
    name = Pipl::Name.new first: 'first', last: 'last'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    dob = Pipl::DOB.new date_range: Pipl::DateRange.new(TODAY - 365, TODAY)

    person = Pipl::Person.new fields: [name, address, phone, dob], match: 0.98, search_pointer: 'search_pointer'
    h = person.to_hash

    expect(h[:search_pointer]).to eq('search_pointer')
    expect(h[:names]).to contain_exactly(name.to_hash)
    expect(h[:addresses]).to contain_exactly(address.to_hash)
    expect(h[:phones]).to contain_exactly(phone.to_hash)
    expect(h[:dob]).to eq(dob.to_hash)
  end

  it 'is searchable with a search_pointer' do
    person = Pipl::Person.new
    expect(person.is_searchable?).to be false
    person = Pipl::Person.new search_pointer: 'search_pointer'
    expect(person.is_searchable?).to be true
  end

  it 'is searchable if at least one of name/username/user_id/phone/email/address is searchable' do
    name = Pipl::Name.new first: 'first', last: 'last'
    email = Pipl::Email.new address: 'test@example.com'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    username = Pipl::Username.new content: 'username@service'
    user_id = Pipl::UserID.new content: 'u9876@service'
    address = Pipl::Address.new city: 'Austin', street: 'North MoPac Expressway', house: 9606, apartment: 'Suite 700'

    person = Pipl::Person.new fields: [name]
    expect(person.is_searchable?).to be true
    person = Pipl::Person.new fields: [username]
    expect(person.is_searchable?).to be true
    person = Pipl::Person.new fields: [user_id]
    expect(person.is_searchable?).to be true
    person = Pipl::Person.new fields: [phone]
    expect(person.is_searchable?).to be true
    person = Pipl::Person.new fields: [email]
    expect(person.is_searchable?).to be true
    person = Pipl::Person.new fields: [address]
    expect(person.is_searchable?).to be true
  end

  it 'returns all non searchable fields' do
    name = Pipl::Name.new first: 'first'
    email = Pipl::Email.new address: 'test@example.com'
    phone = Pipl::Phone.new number: 2123334444, country_code: 1
    username = Pipl::Username.new content: 'username@service'
    address = Pipl::Address.new country: 'US', state: 'AZ', city: 'Phoenix'
    person = Pipl::Person.new fields: [name, email, phone, username, address]
    expect(person.unsearchable_fields.map(&:to_hash)).to contain_exactly(name.to_hash)
  end

end
