#encoding: utf-8
require 'bundler/gem_tasks'
require 'fileutils'

desc '初始化下载和复制discourse代码'
task :init do
	project_root = File.dirname(__FILE__)
	temp_path = project_root + '/tmp'

	FileUtils.rm_rf temp_path
	FileUtils.mkdir_p temp_path
	FileUtils.cd temp_path
	system "git clone git@github.com:discourse/discourse.git"

	onebox_path = project_root + '/lib/oneboxer'
	FileUtils.mkdir_p onebox_path
	static_path = project_root + '/static'
	FileUtils.mkdir_p static_path

	discourse_lib = temp_path + '/discourse/lib'
	discourse_onebox_path = discourse_lib + '/oneboxer'
	our_lib = project_root + '/lib'
	discourse_favicons_path = temp_path + '/discourse/app/assets/images/favicons'
	FileUtils.cp_r discourse_onebox_path,  our_lib
	FileUtils.cp_r discourse_favicons_path,  static_path
	FileUtils.rm_f onebox_path + '/discourse_local_onebox.rb'

	modified_file = onebox_path + '/handlebars_onebox.rb' 
	system "sed -i \'s|Rails.root|$project_root|g\' #{modified_file}"
	system "sed -i \"s|raise ex if Rails.env.development\?||g\" #{modified_file}"
	system "sed -i \"s|ActionController.*favicon_file)|self.class.favicon_file|g\" #{modified_file}"

	modified_file = onebox_path + '/discourse_remote_onebox.rb' 
	system "sed -i \"s|require_dependency \'freedom_patches\/rails4\'||g\" #{modified_file}"

	FileUtils.rm_rf temp_path
end

desc '启动url-onebox服务器'
task :start do
	current_path = File.dirname(__FILE__)
	exec_path = current_path + '/bin/url-onebox-server'
	system "#{exec_path} &"
end

desc '默认，启动服务器，同rake start'
task :default do
	Rake::Task['start'].invoke
end

desc '关闭服务器'
task :stop do
	system "ps aux | awk \'\/bin\\\/url-onebox-server/{print $2}\' | xargs kill -9"
end

desc '从新启动服务器'
task :restart => [:stop, :start]


namespace :log do
	desc '查看最近100条日志'
	task :view do
		log_file = File.dirname(__FILE__) + '/log/server.log'
		system "tail -n 100 #{log_file}"
	end

	desc '删除server.log日志'
	task :clean do
		log_file = File.dirname(__FILE__) + '/log/server.log'
		FileUtils.rm_f log_file
	end
end

desc '同rake log:view'
task :log do
	Rake::Task['log:view'].invoke
end

