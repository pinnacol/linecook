module LineCook
  module TestHelper
    attr_reader :previous_dir
    attr_reader :current_dir

    def setup
      super
      @_tempfiles = []
      @previous_dir = Dir.pwd
      
      # assign current dir from pwd to resolve the full path having followed
      # symlinks -- important because on OSX /var is a symlink to /private/var
      
      Dir.chdir(tempdir)
      @current_dir = Dir.pwd
    end

    def teardown
      Dir.chdir(previous_dir)
      @_tempfiles = nil
      super
    end
    
    def path(relative_path)
      path = File.expand_path(relative_path, current_dir)
    end
    
    def tempdir(base=method_name)
      tempfile = Tempfile.new(base)
      tempfile.close
      @_tempfiles << tempfile
      
      dir = tempfile.path
      
      FileUtils.rm(dir)
      FileUtils.mkdir_p(dir)
      
      dir
    end

    def prepare(relative_path, dir=current_dir, &block)
      block ||= lambda {}
      
      target = File.join(dir, relative_path)
      target_dir = File.dirname(target)
      
      FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
      File.open(target, 'w', &block)

      target
    end
  end
end