Logs in as the specified user for the duration of a block (the current ENV
and pwd are reset as during a normal login).
(user='root', options={})
--
  current = functions
  begin
    @functions = nil

    path = capture_script(options) { yield }
    execute 'su', user, path, :l => true
  ensure
    @functions = current
  end
  