# load all the site specific stuff
config_file = File.join(Rails.root, "config", "site.yml")
if File.exists?(config_file)
	site_specific = YAML.load_file(config_file)
	if Rails.env == 'test'
		SOLR_CORE = 'test'
	else
		SOLR_CORE = site_specific['solr']['core']
	end
	SOLR_PATH = site_specific['solr']['path']
	SUBFOLDER = site_specific['subfolder']
	IMAGE_FOLDER = site_specific['test_data']['image_folder']
	IMAGE_MAGIC_PATH = site_specific['images']['image_magic_path']
	RETURN_PATH = site_specific['smtp_settings']['return_path']
	CONTACT_US_EMAIL =site_specific['admin']['email']

	Rails.application.config.action_mailer.delivery_method = :smtp
	ActionMailer::Base.smtp_settings[:enable_starttls_auto] = true
	ActionMailer::Base.smtp_settings[:address] = site_specific['smtp_settings']['address']
	ActionMailer::Base.smtp_settings[:port] = site_specific['smtp_settings']['port']
	ActionMailer::Base.smtp_settings[:domain] = site_specific['smtp_settings']['domain']
	ActionMailer::Base.smtp_settings[:user_name] = site_specific['smtp_settings']['user_name']
	ActionMailer::Base.smtp_settings[:password] = site_specific['smtp_settings']['password']
	ActionMailer::Base.smtp_settings[:authentication] = site_specific['smtp_settings']['authentication']
	ActionMailer::Base.default_url_options[:host] = RETURN_PATH
	
#if SUBFOLDER && SUBFOLDER.length > 0
#		Rails.application.config.action_controller.relative_url_root = SUBFOLDER
#	end
else
	puts "***"
	puts "*** Failed to load site configuration. Did you create config/site.yml?"
	puts "***"
end

Paperclip.options[:command_path] = IMAGE_MAGIC_PATH
Paperclip.options[:swallow_stderr] = false
