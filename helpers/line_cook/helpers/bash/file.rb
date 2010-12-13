(target, options={})
--
source = file_path(options[:source] || File.basename(target))
install(source, target, options)
