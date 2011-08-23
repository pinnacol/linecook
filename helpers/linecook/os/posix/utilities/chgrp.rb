Change the file group ownership
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/chgrp.html]

(group, *files)
--
  unless group.nil?
    execute 'chgrp', group, *files
  end
  