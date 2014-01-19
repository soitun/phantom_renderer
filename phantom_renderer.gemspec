$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "phantom_renderer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "phantom_renderer"
  s.version     = PhantomRenderer::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of PhantomRenderer."
  s.description = "TODO: Description of PhantomRenderer."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"

end
