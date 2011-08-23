Defines the check status function.

()
--
  function('check_status', nil) do |expected, actual, error, message|
    message.default = '?'
    
    if_ actual.ne(expected) do
      writeln %{echo [#{actual}] #{program_name}:#{message}}
      exit_ error
    end
    
    else_ do
      return_ actual
    end
  end
