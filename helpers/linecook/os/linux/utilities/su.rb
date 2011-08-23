Switches to the specified user for the duration of a block.  The current ENV
and pwd are preserved.
{[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/su.html]

(user='root', options={})
--
  path = capture_script(options) do
    functions.each_value do |function|
      writeln function
    end
    yield
  end
  execute 'su', user, path, :m => true
  