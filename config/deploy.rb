# config valid only for Capistrano 3.1
#lock '3.2.1'



set :application, 'swtkCapTest'
set :repo_url, 'git@github.com:sunsc/test_cap.git'

set :user, "ubuntu"
set :use_sudo, true
set :sudo, "sudo -u ubuntu -i"

set :deploy_to, '/opt/k12ke/cap'

set :default_stage, "development"
set :scm, :git
set :deploy_via, :remote_cache

set :log_level, :debug
set :pty, true # sudo に必要
# Shared に入るものを指定
set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets bundle public/system public/assets}
# RVM
set :rvm_type, :system
set :rvm1_ruby_version, '2.1'
# Unicorn
set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"
# 5回分のreleasesを保持する
set :keep_releases, 5

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  # アプリの再起動を行うタスク
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      as "ubuntu" do
      execute :sudo, :mkdir, '-p', release_path.join('tmp')
      execute :sudo, :touch, release_path.join('tmp/restart.txt')
      end
    end
  end

  # linked_files で使用するファイルをアップロードするタスク
  # deployが行われる前に実行する必要がある。
  desc 'upload important files'
  task :upload do
    on roles(:app) do |host|
      as "ubuntu" do 
      execute :sudo, :mkdir, '-p', "#{shared_path}/config"
      upload!('config/database.yml',"#{shared_path}/config/database.yml")
      upload!('config/secrets.yml',"#{shared_path}/config/secrets.yml")
      end
    end
  end

  # webサーバー再起動時にキャッシュを削除する
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        as "ubuntu" do
        execute :sudo, :rm, '-rf', release_path.join('tmp/cache')
        end
      end
    end
  end

  # Flow の before, after のタイミングで上記タスクを実行
  before :started, 'deploy:upload'
  after :finishing, 'deploy:cleanup'

  # Unicorn 再起動タスク
  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart' # lib/capustrano/tasks/unicorn.cap 内処理を実行
  end

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
=begin
namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
=end
end
