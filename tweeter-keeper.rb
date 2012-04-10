require 'rubygems'
require 'tweetstream'
require 'twitter'
require 'yaml'
require 'date'
require 'time'
require 'twilio-ruby'

config = YAML.load_file('config.yaml')

# set up a client to talk to the Twilio REST API
twilio = Twilio::REST::Client.new config['account_sid'], config['auth_token'];

follow_users = Array[Twitter.user('jefflinwood').id];

TweetStream.configure do |c|
  c.username = config['username']
  c.password = config['password']
  c.auth_method = :basic
  c.parser = :yajl
end

client = TweetStream::Client.new()


client.on_error do |message|
  puts "Error received #{message}"
end

params = Hash.new;
params[:follow] = follow_users;

client.filter(params) do |status|
  if status.text.include? "#talk"
  	twilio.account.sms.messages.create(
  	:from => '+15127820967',
  	:to => '+15125690253',
  	:body => status.text
	)
  end
  puts "#{status.text} - #{status.created_at}"

end
