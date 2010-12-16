module LineCook
  module TestHelper
    attr_reader :previous_dir
    attr_reader :current_dir

    def setup
      super
      @previous_dir = Dir.pwd
      @_tempfile = Tempfile.new(method_name)
      @_tempfile.close
      @current_dir = @_tempfile.path
      
      FileUtils.rm(current_dir)
      FileUtils.mkdir_p(current_dir)
      Dir.chdir(current_dir)
    end

    def teardown
      Dir.chdir(previous_dir)
      @_tempfile = nil
      super
    end

    def prepare(relative_path, &block)
      path = File.join(current_dir, relative_path)

      if block
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless File.exists?(dir)
        File.open(path, 'w', &block)
      end

      path
    end
  end
end