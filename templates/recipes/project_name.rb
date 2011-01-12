#############################################################################
helpers '<%= project_name %>'
attributes '<%= project_name %>'
#############################################################################

# Write to the target script using 'target'
target.puts '# An example script.'

# Helpers are available, as are attributes.
echo *attrs['<%= project_name %>']['letters']
echo *attrs['<%= project_name %>']['numbers']

# Use file_path to register a file into the package
# and return a relative path to it.
cat file_path('file.txt')

# Same for templates.  Provide locals as a trailing hash.
cat template_path('template.txt', :n => 10)
