require "dotgpg/heroku/version"

class Dotgpg
  class Heroku
    class PushError < StandardError; end;
    class PullError < StandardError; end;

    attr_accessor :stage

    def initialize(*args)
      opts = args.first || {}
      @stage = opts[:stage]
      @dotgpg_file = opts[:dotgpg_file]
      self
    end

    def push(force: false)
      unless removed.empty? || !force
        $stdout.puts "The following settings exist on #{stage.app} but not in dotgpg:\n"
        $stdout.puts removed.join("\n")
        $stdout.puts "Either remove these from #{stage.app} or add them to #{dotgpg_file}"
        raise PushError
      end

      unless changed.empty? || !force
        $stdout.puts "Updating the following settings on #{stage.app}:\n"
        $stdout.puts changed.join("\n")
      end

      unless added.empty?
        $stdout.puts "Adding the following settings on #{stage.app}:\n"
        $stdout.puts added.join("\n")
      end

      unless updated.empty?
        heroku.put_config_vars stage.app, updated
      end

      true
    end

    def pull(force: false)
      if File.exists?(dotgpg_file) && !force
        $stdout.puts "#{dotgpg_file} exists, bailing.\n"
        raise PullError
      end

      s = StringIO.new
      heroku_config.sort.each do |k,v|
        # if our value has newlines or #'s it needs to be double-quoted. in
        # addition newlines need to be \n and not actual multi-line strings,
        # see https://github.com/bkeepers/dotenv#usage
        v = v.inspect if v.match(/\n|#/)
        s.write "#{k}=#{v}\n"
      end

      s.rewind
      dir = Dotgpg::Dir.closest dotgpg_file
      fail "#{dotgpg_file} not in a dotgpg directory" unless dir
      dir.encrypt dotgpg_file, s
    end

    def removed
      @removed ||= heroku_config.keys - dotgpg_config.keys
    end

    def changed
      @changed ||= heroku_config.select{|k,v| dotgpg_config[k] && dotgpg_config[k] != v}.keys
    end

    def added
      @added ||= dotgpg_config.keys - heroku_config.keys
    end

    def updated
      @updated ||= dotgpg_config.select{|k,v| (changed + added).include? k}
    end

    private

    def heroku
      stage.heroku
    end

    def heroku_config
      @heroku_config ||= heroku.get_config_vars(stage.app).body
    end

    def dotgpg_file
      # ugly , should probably fail here if we don't have a dotgpg file to read
      @dotgpg_file ||= ::Rails.root.join("config/dotgpg/#{stage.name}.gpg")
    end

    def dotgpg_config
      @dotgpg_config ||= Dotgpg::Environment.new dotgpg_file
    end

    class Railtie < ::Rails::Railtie
      rake_tasks do
        Rake.load_rakefile File.expand_path('../heroku/tasks/dotgpg_heroku.rake', __FILE__).to_s
      end
    end
  end
end

