$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "phantom_renderer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "phantom_renderer"
  s.version     = PhantomRenderer::VERSION
  s.authors     = ["Erez Rabih"]
  s.email       = ["erez.rabih@gmail.com"]
  s.homepage    = "https://github.com/FTBpro/phantom_renderer"
  s.summary     = "A Ruby on Rails Phantom-Server agent."
  s.description = "A Ruby on Rails Phantom-Server agent."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile"]

  s.add_dependency "rails", "~> 3.2.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "coveralls"

end
