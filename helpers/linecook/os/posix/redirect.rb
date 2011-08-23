Makes a redirect statement.

(source, target, redirection='>')
--
  source = source.nil? || source.kind_of?(Fixnum) ? source : "#{source} "
  target = target.nil? || target.kind_of?(Fixnum) ? "&#{target}" : " #{target}"
  
  match = _chain_? ? _rewrite_(trailer) : nil
  write " #{source}#{redirection}#{target}"
  write match[1] if match
  