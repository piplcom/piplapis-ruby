lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pipl/version'

Gem::Specification.new do |spec|
  spec.name = 'piplapis-ruby'
  spec.summary = 'Ruby bindings for the Pipl API'
  spec.description = 'Pipl is the most comprehensive people search on the web. See https://pipl.com for details.'
  spec.homepage = 'https://github.com/piplcom/piplapis-ruby'
  spec.authors = ['Pipl']
  spec.email = ['support@pipl.com']
  spec.license = 'Apache-2.0'
  spec.version = Pipl::VERSION.dup
  spec.files = %w(LICENSE README.md pipl.gemspec)
  spec.files += Dir.glob('lib/**/*.rb')
  spec.require_paths = ['lib']

  spec.add_development_dependency('bundler', '~> 1.6')
end