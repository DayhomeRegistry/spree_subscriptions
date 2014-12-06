Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'spree_subscriptions'
  s.version      = '0.1.1'
  s.summary      = ''
  s.description  = 'Plan subscription functionality for spree'
  s.authors      = ['jonmholt', 'Jon Holt']
  s.email        = ['jon@twentyfivetwenty.ca']
  s.homepage     = 'http://www.twentyfivetwenty.ca'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'
  s.required_ruby_version = '>= 1.9.3'

  #s.add_dependency 'spree_api'
  #s.add_dependency 'spree_backend'
  s.add_dependency 'spree_core', '> 2.3'
  #s.add_dependency 'spree_frontend'

  # test suite
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'coffee-script'
  s.add_development_dependency 'factory_girl_rails', '~> 4.2.0'
  s.add_development_dependency 'rspec-rails', '~> 2.13'
  s.add_development_dependency 'sass-rails', '~> 4.0.2'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'database_cleaner', '1.0.1'
  s.add_development_dependency 'simplecov', '~> 0.7.1'
end
