require 'twitter'
require 'oauth'
require 'time'

USER_NAME="myyahele_"
CONSUMER_KEY = "pnUZ4c6D4iZswVLM1VhOSA"
CONSUMER_SECRET = "OR3TsOc84Lv87BjQQofY1paovqjwGSe6LsWnE1qUnSQ"
ACCESS_TOKEN_KEY = "95394941-fI5aq1I1uozueZr41kiUHzDH2lg8uhBeWCeyHuumI"
ACCESS_SECRET = "p7nGMOUQWwdZv6rK09qwxZo5WDmTG1m51N3cbkW2VU"
COUNT = 100
PAGE = 10

class GetweetController < ApplicationController

  def index
  end
  
  def get
    Twitter.configure do |config|
      config.consumer_key = CONSUMER_KEY
      config.consumer_secret = CONSUMER_SECRET
      config.oauth_token = ACCESS_TOKEN_KEY
      config.oauth_token_secret = ACCESS_SECRET
    end
    name = params[:name]
    #name = "dada_ideal"
    timeline = Array.new
    @tweets = Array.new
    @friends = Array.new
    
    #ids = Twitter.friend_ids(name).ids[0,100]
    #users = Twitter.users(ids)
    #users.each do |info|
    #  @friends << info['screen_name']
    #end
    #idx = @friends.length
    #idx = rand(idx)
    for page in (1..PAGE) do 
      timeline << Twitter.user_timeline(name,{:count => COUNT,:page => page})
    end
    for i in timeline
      for j in i
        @tweets << j[:text] 
      end
    end
    @who = 0
    # @who = @friends[idx]
    # res = Twitter.users("myyahele_")
  
    
    # user = Twitter.user("dada_ideal")
    # user_friends_count = user.friends_count
    # friends_ids = Hash.new
    # friends_ids = Twitter.friend_ids("dada_ideal")
    # @ids = Array.new
    # @ids = friends_ids["ids"]
  end

  def serch
    str = params[:name]
    @arr = Array.new
    Twitter.search("to:justinbieber marry me", :count => 3, :result_type => "recent").results.map do |status|
      @arr << "#{status.from_user}: #{status.text}"
    end
  end
end
