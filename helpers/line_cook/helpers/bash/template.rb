(target, options={})
--
locals = options[:locals] || {:attrs => attrs}
source = template_path(options[:source] || File.basename(target), locals)
install(source, target, options)
