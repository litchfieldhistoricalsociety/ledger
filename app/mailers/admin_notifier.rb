class AdminNotifier < ActionMailer::Base
#	default :from => EXCEPTION_SENDER
#	default :to => EXCEPTION_RECIPIENTS

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.actionmailer.admin_notifier.no_solr.subject
  #
  def no_solr
    @greeting = "The server could not connect to solr at #{Time.now}."

    #mail :subject => "#{EXCEPTION_PREFIX}Solr error"
  end

	def contact(name, email, description, referrer)
		@greeting = "#{name} has some information for page #{referrer}.\nContact info: #{email}\n\n#{description}"
#		mail :subject => "#{EXCEPTION_PREFIX}More Information", :to => CONTACT_US_EMAIL
	end
end
