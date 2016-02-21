class Dotgpg::Heroku::RakeUtils
  def self.pull(force: false)
    each_heroku_app do |stage|
      begin
        dotgpg_heroku = Dotgpg::Heroku.new stage: stage
        dotgpg_heroku.pull force: force
      rescue Dotgpg::Heroku::PullError => e
        # if we get one of these we don't want a long stack trace dumped
        # to the screen (because the user won't be able to read the message that's
        # printed before the stack trace) so we rescue and exit
        exit 255
      end
    end
  end

  def self.push(force: false)
    each_heroku_app do |stage|
      begin
        dotgpg_heroku = Dotgpg::Heroku.new stage: stage
        dotgpg_heroku.push force: force
      rescue Dotgpg::Heroku::PullError => e
        # if we get one of these we don't want a long stack trace dumped
        # to the screen (because the user won't be able to read the message that's
        # printed before the stack trace) so we rescue and exit
        exit 255
      end
    end
  end

  # TODO - this should be shared, maybe by dotgpg-environment? dotgpg-rails also
  # has a variation on this
  def self.init
    require 'fileutils'
    require 'dotgpg'

    # create config/dotgpg if it doesn't already exist
    dir = ::Rails.root.join 'config/dotgpg'
    unless File.directory?(dir)
      $stdout.puts "Creating #{dir}"
      FileUtils.mkdir_p dir
    end

    # setup dotgpg directory if necessary
    dotgpg_dir = Dotgpg::Dir.new(dir)
    unless dotgpg_dir.dotgpg?
      begin
        $stdout.puts "Initializing dotgpg directory #{dir}"
        Dir.chdir dir
        Dotgpg.interactive = true
        Dotgpg::Cli.start ['init']
      ensure
        # make sure thor didn't overwrite STDIN/STDOUT/STDERR
        $stderr = STDERR
        $stdin = STDIN
        $stdout = STDOUT

        # and change back to our RAILS_ROOT
        Dir.chdir ::Rails.root
      end
    end
  end

  def self.init_heroku
    # for each of the environments that require dotgpg-rails initialize a blank
    # dotgpg file in config/dotgpg/environment.gpg
    HerokuSan.project.all.reject{|s| s == 'default'}.each do |stage|
      path = File.join dir, "#{stage}.gpg"
      next if File.exists? path
      $stdout.puts "Initializing empty dotgpg file #{path}"
      dotgpg_dir.encrypt path, "# placeholder dotgpg file for #{stage} environment.\n"
    end
  end
end

# do a push before we try to deploy
task :before_deploy => [:environment] do
  Rake::Task["dotgpg:heroku:push"].invoke
end

# sync our environments up
namespace :dotgpg do
  namespace :heroku do
    desc "Push dotgpg environment to heroku"
    task :push => [:environment] do
      Dotgpg::Heroku::RakeUtils.push
    end

    namespace :push do
      desc "Forcibly push dotgpg environment to heroku, overwriting any conflicting remote values"
      task :force => [:environment] do
        Dotgpg::Heroku::RakeUtils.push force: true
      end
    end

    desc "Pull dotgpg environment from heroku"
    task :pull => [:environment] do
      Dotgpg::Heroku::RakeUtils.pull
    end

    namespace :pull do
      desc "Forcibly pull dotgpg environment from heroku, overwriting any conflicting local values"
      task :force => [:environment] do
        Dotgpg::Heroku::RakeUtils.pull force: true
      end
    end

    desc "Init dotgpg directories"
    task :init => [:environment] do
      Dotgpg::Heroku::RakeUtils.init
      Dotgpg::Heroku::RakeUtils.init_heroku
    end

  end
  alias_task :push => 'dotgpg:heroku:push'
  alias_task :pull => 'dotgpg:heroku:pull'
  alias_task 'pull:force' => 'dotgpg:heroku:pull:force'
  alias_task :init => 'dotgpg:heroku:init'
end
