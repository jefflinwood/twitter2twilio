require 'rubygems'
require 'tweetstream'
require 'twitter'
require 'yaml'
require 'date'
require 'time'
require 'twilio-ruby'
require 'redis'


uri = URI.parse("redis://redistogo:d8ac5e0e424be10192ec7bf60d44d3b5@herring.redistogo.com:9800/")
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)


config = YAML.load_file('config.yaml')

# set up a client to talk to the Twilio REST API
twilio = Twilio::REST::Client.new config['account_sid'], config['auth_token'];

follow_users = Array[Twitter.user(config['username_to_follow']).id];

sms_followers = Array['+15125690253','+15127910975'];

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
  if status.text.include? "#talk" || status.text.include? "#hack"
    sms_followers = REDIS.smembers "sms_followers"
    for sms in sms_followers do
    	twilio.account.sms.messages.create(
    	:from => config['from_number'],
    	:to => sms,
    	:body => status.text
  	)
    end
  end
  puts "#{status.text} - #{status.created_at}"

end
