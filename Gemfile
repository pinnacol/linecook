source "http://rubygems.org"

# Setup gemspec dependencies manually
# (see https://github.com/carlhuda/bundler/issues/issue/916)

project_dir = File.expand_path('..', __FILE__)
gemspec_path = File.expand_path('linecook.gemspec', project_dir)

gemspec = Gem::Specification.load(gemspec_path)
gemspec.dependencies.each do |dep|
  group = dep.type == :development ? :development : :default
  gem dep.name, dep.requirement, :group => group
end

path project_dir, :glob => 'linecook.gemspec' do
  gem gemspec.name, gemspec.version
end