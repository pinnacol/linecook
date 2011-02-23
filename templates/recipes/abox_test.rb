#############################################################################
helpers '<%= project_name %>'
attributes '<%= project_name %>'
#############################################################################

# Validations can be using the same techniques as in run.
assert_content_equal %{
I will automate configuration of my servers.
}.lstrip, '~/2011/resolutions.txt'

assert_content_equal %{
# TODO
* automate configuration of my servers
}.lstrip, '~/2011/todo.txt'
