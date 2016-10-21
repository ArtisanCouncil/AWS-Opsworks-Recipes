# # Success / fail email function
define :send_email do 
    options ||= {}
    now = ::Time.now.utc.iso8601 
    name = node.name 

    options[:subject]       ||= "Chef run on #{name} @ #{now}"
    options[:body]          ||= ''
    options[:from]          ||= 'chef@artisancouncil.com'
    options[:from_alias]    ||= 'Chef Opsworks'
    #options[:to]            ||= 'support@artisancouncil.com' #TODO create support email


	#create message
    message = "" 
    message << "Subject: #{options[:subject]}\n"
    message << "#{options[:body]}\n"
    Chef::Log.info "AC-SETUP::base email message:" << message

    smtp = Net::SMTP.new 'smtp.gmail.com', 587  # initialize smtp obj w/ gmail settings
    smtp.enable_starttls                        # required to send emails via gmail

	#send message
    #smtp.start('artisancouncil.com', 'support@artisancouncil.com', 'F4nta51k3k', :login) do 
    #    smtp.send_message(message, options[:from], options[:to]) # message, sender, receiver
    #end
end 
