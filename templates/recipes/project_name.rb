# Include any helpers/attributes used by this recipe
helpers '%project_name%'
attributes '%project_name%'

# Write to the script target using 'script'
script.puts '# An example script.'

# Helpers are now available, as are attributes.
echo *attrs['%project_name%']['letters']
echo *attrs['%project_name%']['numbers']