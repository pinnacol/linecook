#############################################################################
attributes '<%= project_name %>'
helpers '<%= project_name %>'
#############################################################################

# Write to the script using write/writeln
writeln '# An example script.'

# Attributes are available via attrs.
# Helpers are available as methods.
echo attrs['<%= project_name %>']['message']

# Use file_path and template_path to add files to the package; the return
# value can be treated as a path to the file.  For example:
writeln "cat #{file_path('example.txt', 'example_file')}"
writeln "cat #{template_path('example.txt', 'example_template')}" 
