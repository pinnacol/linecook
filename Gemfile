#############################################################################
# This is a standard Gemfile for setting up bundling in the Pinnacol env.
# Normally you should specify dependencies through the gemspec rather than
# editing this file, ie:
#   
#   Gem::Specification.new do |s|
#     ... 
#     s.add_dependency("rack")
#     s.add_development_dependency("rack-test")
#   end
#
# Development dependencies will not be activated in production environments
# like prd, acp, qa, etc. (this only applies to applications; gems resolve
# dependencies using gemspecs when deployed, regardless of environment).
#############################################################################

project_dir = File.expand_path('..', __FILE__)
gemspec_path = File.expand_path('line_cook.gemspec', project_dir)

#
# Setup gemspec dependencies
#

gemspec = eval(File.read(gemspec_path))
gemspec.dependencies.each do |dep|
  group = dep.type == :development ? :development : :default
  gem dep.name, dep.requirement, :group => group
end
gem(gemspec.name, gemspec.version, :path => project_dir, :require => nil)

#
# Setup sources
#

source 'http://gems.pinnacol.com'

case ENV['WCIS_ENV']
when 'prd', 'acp', 'qa', 'tst'
  # no additional sources -- pinnacol only
  
when 'cc'
  source :gemcutter
  path ENV['CRUISE_DATA_ROOT'], :glob => 'projects/*/work/*.gemspec'
  
else
  source :gemcutter
  path project_dir, :glob => 'vendor/*/*.gemspec'
  
end
