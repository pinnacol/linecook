_package_.unregister(target)
_package_.register('run', target, :mode => 0744)
public_key = File.read File.expand_path("~/.ssh/id_rsa.pub")

writeln "#!/bin/sh"
write %{
mkdir .ssh
echo '#{public_key}' > .ssh/authorized_keys
chmod 0700 .ssh
chmod 0600 .ssh/authorized_keys
sudo rm /etc/motd
}