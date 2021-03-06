namespace :scraper do
  desc "Fetch Craigslist posts from 3Taps"
  task scrape: :environment do
	require 'open-uri'
	require 'json'

	# Set API and URL
	auth_token="9017101c39d410872d7d66509bd4089f"
	polling_url="http://polling.3taps.com/poll"

	# Grab data until up to date

	loop do

	# Request Parameters
	params = {
	  auth_token: auth_token,
	  anchor: Anchor.first.value,
	  source: "CRAIG",
	  category_group: "RRRR",
	  category: "RHFR",
	  'location.metro' => "CAN-YYZ",
	  retvals: "location,external_url,heading,body,timestamp,price,images,annotations"
	}

	# Prepare API request
	uri = URI.parse(polling_url)
	uri.query = URI.encode_www_form(params)

	# Submit request
	result = JSON.parse(open(uri).read)


	# Displays Results
	# puts result["postings"].first["images"].first["full"]
	
	result["postings"].each do |posting|

      # Create new Post
      @post = Post.new
      @post.heading = posting["heading"]
      @post.body = posting["body"]
      @post.price = posting["price"]
      @post.external_url = posting["external_url"]
      @post.timestamp = posting["timestamp"]
	  @post.bedrooms = posting["annotations"]["bedrooms"] if posting["annotations"]["bedrooms"].present?
	  @post.bathrooms = posting["annotations"]["bathrooms"] if posting["annotations"]["bathrooms"].present?
	  @post.sqft = posting["annotations"]["sqft"] if posting["annotations"]["sqft"].present?
	  @post.cats = posting["annotations"]["cats"] if posting["annotations"]["cats"].present?
	  @post.dogs = posting["annotations"]["dogs"] if posting["annotations"]["dogs"].present?
	  
	  # Save Post
      @post.save

      #Loop over images and save to Image database
	    posting["images"].each do |image|
	      @image = Image.new
	      @image.url = image["full"]
	      @image.post_id = @post.id 
	      @image.save
        end  
    end

    Anchor.first.update(value: result["anchor"])
    puts Anchor.first.value
    break if result["postings"].empty?
	end
end

  desc "Destroy all posting data"
  task destroy_all_posts: :environment do
  	Post.destroy_all
  end

  desc "Discard old data"
  task discard_old_data: :environment do
    Post.all.each do |post|
      if post.created_at < 6.hours.ago
        post.destroy 
      end
    end
  end

end
