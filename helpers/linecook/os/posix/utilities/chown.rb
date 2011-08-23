Change the file ownership.
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chown.html]

(owner, *files)
--
  unless owner.nil?
    execute 'chown', owner, *files
  end