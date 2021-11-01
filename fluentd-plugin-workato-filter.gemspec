lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluentd-plugin-workato-filter"
  spec.version       = '0.0.2'
  spec.authors       = ["Vadim Shauslki"]
  spec.email         = ["vadim.shauslki@workato.com"]

  spec.summary       = %q{fluentd plugin for workato logs parser}

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "test-unit", "~> 3.3.1"
  spec.add_development_dependency "fluentd", "~> 1.14.2"
  spec.add_development_dependency "pry-byebug", "~> 3.7.0"
end
