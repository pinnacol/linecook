# Returns an expression that evaluates to the program dir, assuming that
# $0 evaluates to the full path to the current recipe.
def program_dir
  '$(dirname "$0")'
end
