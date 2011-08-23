Delete a user account and related files.
{[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/userdel.html]

(login, options={}) 
--
  # TODO - look into other things that might need to happen before:
  # * kill processes belonging to user
  # * remove at/cron/print jobs etc. 
  execute 'userdel', login, options
