#############################################################################
helpers '<%= project_name %>'
attributes '<%= project_name %>'
#############################################################################

# Write to the script using write/writeln
writeln '# An example script.'

# Attributes are available, as are helpers.
file = "~/#{attrs['<%= project_name %>']['year']}/resolutions.txt"
content = attrs['<%= project_name %>']['resolutions'].join("\n")
create_file file, content

# Use file_path to add a file to the package and return a path to it.
source = file_path('help.txt')
target = "~/#{attrs['<%= project_name %>']['year']}/help.txt"
install_file source, target

# Same for templates.  Attributes are available in the template.
source = template_path('todo.txt')
target = "~/#{attrs['<%= project_name %>']['year']}/todo.txt"
install_file source, target
