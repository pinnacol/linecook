Set or unset options as specified. For example:

  set 'x' => true, 'v' => false

If a block is given then options will only be reset when the block completes.
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25]

(options)
--
  if block_given?
    var = _package_.next_variable_name('set')
    patterns = options.keys.collect {|key| "-e #{key}" }.sort
    writeln %{#{var}=$(set +o | grep #{patterns.join(' ')})}
  end

  options.keys.sort_by {|opt| opt.to_s }.each do |opt|
    writeln %{set #{options[opt] ? '-' : '+'}o #{opt}}
  end

  if block_given?
    yield
    writeln %{eval "$#{var}"}
  end