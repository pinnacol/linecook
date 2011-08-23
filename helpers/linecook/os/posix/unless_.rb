Executes the block when the expression evaluates to a non-zero value.

(expression)
--
  if_("! #{expression}") { yield }