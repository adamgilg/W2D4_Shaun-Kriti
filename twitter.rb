require "oauth"
require "yaml"
require "addressable/uri"
require "json"

class TwitterClient
  CONSUMER_KEY = "ypwme7dRVJWxGpJKlG7Q"
  CONSUMER_SECRET = "g87WDlHg11jR6vcQruIUtJ5kC1ArbzwuW2hIhrQANs"

  CONSUMER = OAuth::Consumer.new(
    CONSUMER_KEY, CONSUMER_SECRET, :site => "http://twitter.com")

  def initialize
    get_token
  end

  def get_token
    if File.exist?("token.yaml")
      str = File.read("token.yaml").chomp
      @access_token = YAML::load(str)
    else
      request_token = CONSUMER.get_request_token
      puts "Go to this URL: #{request_token.authorize_url}"
      puts "Login, and type your verification code in"
      oauth_verifier = gets.chomp
      @access_token = request_token.get_access_token(
        :oauth_verifier => oauth_verifier )
      File.open('token.yaml', 'w') do |f|
        YAML.dump(@access_token, f)
      end
    end
  end

  def run
    puts "What would you like to do??"
    puts "Tweet(T), Direct Message (DM), Get Timeline (GT), Get Other User's status (O)"
    case gets.chomp.upcase
    when "T"
      post_status
    when "DM"
      direct_message
    when "GT"
      get_timeline
    when "O"
      get_other_users_status
    else
      puts "Learn how to type... Dummy."
    end
  end

  def post_status
    puts "Enter the msg you want to post:"
    status = gets.chomp
    tweet = {:status => status }

    @access_token.post("https://api.twitter.com/1.1/statuses/update.json", tweet)
    puts "Your tweet has been twat."
  end

  def get_timeline
    puts "How many of your tweets would you like to see?"
    count = gets.chomp
    host_request = Addressable::URI.new(
          :scheme => "https",
          :host => "api.twitter.com",
          :path => "/1.1/statuses/user_timeline.json",
          :query_values => {
            :count => count}).to_s

    timeline = JSON.parse(@access_token.get(host_request).body)
    puts "Here's your timeline:"
    print_timeline(timeline)
    puts
  end

  def get_other_users_status
    puts "Who's status would you like to find (screen_name)?"
    screen_name = gets.chomp
    puts "How many of their tweets would you like to see?"
    count = gets.chomp
    host_request = Addressable::URI.new(
          :scheme => "https",
          :host => "api.twitter.com",
          :path => "/1.1/statuses/user_timeline.json",
          :query_values => {
            :screen_name => screen_name,
            :count => count}).to_s

    timeline = JSON.parse(@access_token.get(host_request).body)
    puts "Here's @#{screen_name}'s timeline:"
    print_timeline(timeline)
  end

  def direct_message
    puts "Who would you like to direct message (screen_name)?"
    puts "Please make sure they are one of your minions...."
    screen_name = gets.chomp
    puts "What would you like to tweet to them?"
    text = gets.chomp
    host_request = Addressable::URI.new(
          :scheme => "https",
          :host => "api.twitter.com",
          :path => "/1.1/direct_messages/new.json").to_s
    tweet = {
        :text => text,
        :screen_name => screen_name}

    @access_token.post(host_request, tweet)
    puts "Your tweet has been twat"
  end

  def print_timeline(timeline)
    timeline.each do |tweet|
      puts
      overall_time = tweet["created_at"].split
      overall_time.delete_at(-2)
      time = overall_time.delete_at(-2)[0..4]
      date = "#{overall_time[0]}, #{overall_time[1, 2].join(" ")}, #{overall_time[3]}"
      puts "Tweeted on #{date} at #{time}"
      puts "Tweet: #{tweet["text"]}"
    end
  end
end

TwitterClient.new.run