capture_path 'run', :mode => 0744 do
  writeln "echo #{attrs['letters'].join(' ')}"
end