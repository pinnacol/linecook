helpers '%project_name%'
attributes '%project_name%'

# Access attributes and write to the script target
# target.puts "echo #{attrs[:%project_name%][:key]}"

# Definitions included via 'helpers'
echo_args 'a', 'b', 'c'
