Change the file modes. The mode may be specified as a String or a Fixnum. If a
Fixnum is provided, then it will be formatted into an octal string using
sprintf "%o".
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chmod.html]

(mode, *files)
--
  unless mode.nil?
    if mode.kind_of?(Fixnum)
      mode = sprintf("%o", mode)
    end
    execute 'chmod', mode, *files
  end