shell 'bash'
helpers '<%= project_name %>'
attributes '<%= project_name %>'

# Access attributes and write directly to the target
# target.puts "echo #{attrs[:demo][:key]}"

# Execute a command and check the exit status
# execute "true"

# Conditionals
# only_if("true") { echo "was true" }
# not_if("false") { echo "was false" }

# File system operations
# (options like {:mode => 755, :user => 'root', :group => 'root'})
#
# * Create a directory
# directory '/target', options
#
# * Install 'files/target'
# file '/target', options
#
# * Template and install 'templates/target.erb'
# template '/target', options
#
# * Create a symlink
# ln_s '/source', '/target'

# Packages
# package 'package_name', '1.0.0'
# gem_package 'gem_name', '1.0.0'

# Other Recipes
# recipe 'recipe_name'

# Definitions included via 'helpers'
# echo_args 'a', 'b', 'c'
# reverse_echo_args 'a', 'b', 'c'
