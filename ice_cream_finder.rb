require "json"
require "rest-client"
require 'addressable/uri'
require 'nokogiri'


class IceCreamFinder
#AG: We hid our API key in a separate file that we required in
#AG: and then put in a .gitignore file so that file didn't get added to the repo
  API_KEY = "AIzaSyCEhaLs5Wf7UPLjD_3o-O9Wlf9eNaG4E-A"

  def initialize
  #AG: Slightly (ie totally) unnecessary initialize, but I like your style. 
    puts "Hey, there! Welcome to Icecream finder :)"
  end

  def find
    puts "We get you to ice cream.... fast"
    puts "Please enter your current location:"
    geocode = get_geocode
    location = parse_location(geocode["results"][0])
    puts "In what radius are you looking?"
    radius = gets.chomp
    icecream_locs_json = find_nearby_icecream(location, radius)
    results = parse_icecream_locs(icecream_locs_json)
    print_results(results)
    puts "Choose an icecream shop to visit (by #)"
    dest = gets.chomp.to_i
    dest_location = results[dest-1][:loc]
    directions = get_directions(location, dest_location)
    adjusted_directions = adjust_directions(directions["routes"][0])
    print_directions(adjusted_directions)
    puts
    make_clown
  end
#AG: more of this, please.
  def make_clown
    puts "Enjoy your nomnom!"
    puts " @@ "
    puts " / \\"
    puts "======"
    puts "| 0 0|"
    puts "|  > |"
    puts "| )= |"
    puts " \\__/"
    puts
  end

  def get_geocode
    address = gets.chomp.split(" ")
    #AG: Addressable will do the joining for you - no need to split/join at all
    address = address.join("+")

    host_request = Addressable::URI.new(
          :scheme => "http",
          :host => "maps.googleapis.com",
          :path => "/maps/api/geocode/json",
          :query_values => {
            :address => address,
            :sensor => "false"}).to_s

    JSON.parse(RestClient.get(host_request))
  end

  def parse_location(geocode)
    lat = geocode["geometry"]["location"]["lat"]
    lng = geocode["geometry"]["location"]["lng"]
    [lat, lng].join(",")
  end

  def find_nearby_icecream(location, radius)
    host_request = Addressable::URI.new(
                :scheme => "https",
                :host => "maps.googleapis.com",
                :path => "/maps/api/place/nearbysearch/json",
                :query_values => {
                  :location => location,
                  :radius => radius,
                  :keyword => "ice cream",
                  :sensor => "false",
                  :key => API_KEY}).to_s

    JSON.parse(RestClient.get(host_request))
  end

  def parse_icecream_locs(locs)
    results = []

    locs["results"].each do |result|
      output = {}
      output[:name] = result["name"]
      output[:loc] = parse_location(result)
      output[:rating] = result["rating"]
      # output[:open] = result["opening_hours"]["open_now"]
      results << output
    end

    results
  end

  def print_results(results)
    results.each_with_index do |result, i|
      if i < 9
        print "#{i+1}.  "
      else
        print "#{i+1}. "
      end
      print result[:name]
      if result[:rating].nil?
        print " (rating: n/a) "
      else
        print " (rating: #{result[:rating]})"
      end
      puts
    end
  end

  def get_directions(start_loc, end_loc)
    host_request = Addressable::URI.new(
                :scheme => "https",
                :host => "maps.googleapis.com",
                :path => "/maps/api/directions/json",
                :query_values => {
                  :origin => start_loc,
                  :destination => end_loc,
                  :sensor => "false",
                  :mode => "walking"}).to_s

    JSON.parse(RestClient.get(host_request))
  end

  def adjust_directions(directions)
    route = {}
    route_legs = directions["legs"][0]
    route[:distance] = route_legs["distance"]["text"]
    route[:time] = route_legs["duration"]["text"]
    route[:start_loc] = route_legs["start_address"]
    route[:end_loc] = route_legs["end_address"]
    route_steps = route_legs["steps"]
    steps = []
    route_steps.each do |step|
      this_step = {}
      this_step[:instructions] = Nokogiri::HTML(step["html_instructions"]).text
      this_step[:dist] = step["distance"]["text"]
      this_step[:time] = step["duration"]["text"]
      steps << this_step
    end
    route[:steps] = steps
    route
  end

  def print_directions(route)
    puts "Going from: #{route[:start_loc]}"
    puts "To: #{route[:end_loc]}"
    puts
    puts "Distance of #{route[:distance]}, taking approx #{route[:time]}."
    puts
    puts "Walking directions:"
    route[:steps].each_with_index do |step, i|
      print "#{i+1}. "
      print step[:instructions]
      print " for a distance of #{step[:dist]}, taking approx #{step[:time]}"
      puts
    end
  end
end

IceCreamFinder.new.find
