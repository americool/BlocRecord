Gem::Specification.new do |s|
  s.name          = 'blocrecord'
  s.version       = '0.0.0'
  s.date          = '2016-20-02' #current date right?
  s.summary       = 'BlocRecord ORM'
  s.description   = 'An ActiveRecord-esque ORM adaptor'
  s.authors       = ['Abe Anderson']
  s.email         = 'aberanderson@gmail.com'
  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.homepage      = 'http://rubygems.org/gems/bloc_record'
  s.license       = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
end
