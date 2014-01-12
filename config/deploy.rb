set :application, "potweeps"
set :repository,  "git@github.com:bradb/potweeps.git"
set :scm, :git
set :branch, :master
set :use_sudo, false
set :user, "deploy"
role :web, "1.1.1.1"                          # Your HTTP server, Apache/etc
role :app, "1.1.1.1"                          # This may be the same as your `Web` server
role :db,  "1.1.1.1", :primary => true # This is where Rails migrations will run

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts
set  :deploy_to, "/var/www/apps/potweeps/"
set  :current_path, "/var/www/apps/potweeps/current"

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after :deploy do
  puts "Creating photos symlink..."
  run "ln -s #{shared_path}/system/photos #{current_path}/public/images/photos"
  puts "done."
  
  puts "Creating database.yml symlink..."
  run "ln -s #{shared_path}/system/database.yml #{current_path}/config/database.yml"
end
