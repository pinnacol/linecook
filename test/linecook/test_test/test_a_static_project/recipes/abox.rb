capture_path 'run' do
  writeln "echo #{attrs['letters'].join(' ')}"
end

_package_.on_export 'run', :mode => 0744
