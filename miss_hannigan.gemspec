$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "miss_hannigan/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "miss_hannigan"
  spec.version     = MissHannigan::VERSION
  spec.authors     = ["n8", "bradleybuda", "avaynshtok", "sean-lynch", "davehughes", "bjabes"]
  spec.email       = ["nate.kontny@gmail.com"]
  spec.homepage    = "https://rubygems.org/gems/miss_hannigan"
  spec.summary     = "An alternative way to do cascading deletes in Rails."
  spec.description = "If neither :destroy or :delete_all work for you when deleting children in Rails, maybe this is the right combination for you."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.1"

  spec.add_development_dependency "sqlite3"
end
