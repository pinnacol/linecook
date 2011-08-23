Change the working directory, for the duration of a block if given.
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cd.html]

(directory=nil, options={})
--
  if block_given?
    var = _package_.next_variable_name('cd')
    writeln %{#{var}=$(pwd)}
  end

  execute 'cd', directory, options

  if block_given?
    yield
    execute 'cd', "$#{var}"
  end