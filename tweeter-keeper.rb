require 'rubygems'
require 'tweetstream'
require 'twitter'
require 'yaml'
require 'date'
require 'time'
require 'twilio-ruby'
require 'redis'

config = YAML.load_file('config.yaml')

uri = URI.parse(config['redis_url'])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

# set up a client to talk to the Twilio REST API
twilio = Twilio::REST::Client.new config['account_sid'], config['auth_token'];

follow_users = Array[Twitter.user(config['username_to_follow']).id];

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
  if (!status.text.start_with? "RT")
    if (status.text.include? "#talk") || (status.text.include? "#hack" ) || (status.text.include? "#bof" )
      sms_followers = REDIS.smembers "sms_followers"
      for sms in sms_followers do
        twilio.account.sms.messages.create(
        :from => config['from_number'],
        :to => sms,
        :body => status.text
      )
      end
    end
  end
  puts "#{status.text} - #{status.created_at}"
end
