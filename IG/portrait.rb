$:.unshift File.dirname(__FILE__)
require "rubygems"
require "instagram"
require_relative "config"

include IotasticConfig

NUM_FRAMES_PER_IMAGE = 10
BLUR_W = 50

def setup
  size 640, 640
  background 0

  # secs_for_frame = 10.0
  # frame_rate 1/secs_for_frame
  frame_rate 1

  # All methods require authentication (either by client ID or access token).
  # To get your Instagram OAuth credentials, register an app at http://instagr.am/oauth/client/register/
  refresh_image_set

  @frame_idx = 0
end

def draw
  # image(next_image, 0, 0)

  @frame_idx = @frame_idx % NUM_FRAMES_PER_IMAGE
  puts "@frame_idx: #{@frame_idx}"
  @img = next_image if (@frame_idx == 0)
  load_pixels

  @frame_idx += 1

  display_pixels_from @img, @frame_idx
end

def refresh_image_set
  @images = iolani_images
  @start_index = rand(@images.size) # Start at random offset.
  @i = @start_index
end

def iolani_images
  Instagram.configure do |config|
    config.client_id    = app_config[:client_key]
    # config.access_token = app_config[:access_token]
  end
  Instagram.media_search("21.285055801","-157.824572373")
end

def next_image
  refresh_image_set if @i == @start_index

  index = @i % @images.size
  puts "index: #{index}"
  url = @images[index].images.standard_resolution.url
  format = url.split(".").last
  web_image = load_image(url, format)
  @i += 1

  return web_image
end

def display_pixels_from img, frame_idx
  push_style

  no_stroke

  skip = map(frame_idx, 0, NUM_FRAMES_PER_IMAGE, BLUR_W, 1).to_i
  # skip = 10
  # // Since we are going to access the image's pixels too  
  img.load_pixels
  num_pix = img.pixels.size
  (0...height.to_i).each do |y|
    next unless (y%skip) == 0

    (0...width.to_i).each do |x|
      next unless (x%skip) == 0

      # puts "x y: #{x} / #{y}"
      loc = x + y*width
      break if loc >= num_pix
      
      r = red(img.pixels[loc])
      g = green(img.pixels[loc])
      b = blue(img.pixels[loc])

      # pixels[loc] = color(r,g,b)
      fill(color(r,g,b))
      rect(x,y,skip,skip)
    end
  end
  # update_pixels

  pop_style
end



# Instagram.media_popular
# ‘Iolani School: 21°17'19.0"N 157°49'38.0"W
# 21.2886111111111111, -157.8272222222222222
# 21.289583, -157.827317

# require 'geocoder'
# Geocoder.search "563 Kamoku St., Honolulu, HI 96826"
# "lat"=>21.2848944, "lng"=>-157.8239182
# Instagram.location_search("21.2848944","-157.8239182")

# # Got this back from the API (500 error):
# {"meta":{"code":200},"data":[{"latitude":21.285114,"id":"25717519","longitude":-157.823799,"name":"Iolani Marching Band"},{"latitude":21.285419404,"id":"44586556","longitude":-157.823838852,"name":"Arena"},{"latitude":21.284406289,"id":"11272492","longitude":-157.823687491,"name":"Manoa Falls"},{"latitude":21.285055801,"id":"81980","longitude":-157.824572373,"name":"\u02bbIolani School"},{"latitude":21.28495256,"id":"8276345","longitude":-157.82320293,"name":"St Albans Chapel"},{"latitude":21.283896302,"id":"2323736","longitude":-157.823926176,"name":"Iolani Fair"},{"latitude":21.285899,"id":"26004499","longitude":-157.824018,"name":"The Old Man's House"},{"latitude":21.285927005,"id":"100157677","longitude":-157.823664205,"name":"Royal Iolani Diamond Head Tower"},{"latitude":21.285486,"id":"20091865","longitude":-157.824963,"name":"Don't Touch The Drums Halau"},{"latitude":21.285847663,"id":"22316839","longitude":-157.824682983,"name":"Iolani School Gymnasium"},{"latitude":21.285995306,"id":"515633","longitude":-157.824502514,"name":"Royal Iolani - Eva Tower"},{"latitude":21.283663992,"id":"8276299","longitude":-157.823856317,"name":"Kukui High School"},{"latitude":21.284882998,"id":"17562884","longitude":-157.822441671,"name":"Iolani School Graduation"},{"latitude":21.286284461,"id":"44129724","longitude":-157.823763172,"name":"Orgrimmar"},{"latitude":21.283661829,"id":"527787","longitude":-157.823000543,"name":"DoubleTree Alana Waikiki"},{"latitude":21.283365315,"id":"52533707","longitude":-157.824316223,"name":"Lei of Parks"},{"latitude":21.286129692,"id":"11037128","longitude":-157.822691999,"name":"Costco Tire Center Hawaii Kai"},{"latitude":21.284984,"id":"46641664","longitude":-157.822093,"name":"Josh and Steff's Place"},{"latitude":21.286422709,"id":"4446854","longitude":-157.823064581,"name":"The Beach House Pool"},{"latitude":21.285055747,"id":"43664937","longitude":-157.822039981,"name":"Bar"}]}
# # Pulled the Iolani lat/long out:
# {"latitude":21.285055801,"id":"81980","longitude":-157.824572373,"name":"\u02bbIolani School"}
# Instagram.location_search("21.285055801","-157.824572373")

# Instagram.media_search("21.285055801","-157.824572373")
# >> ipics.first.images.first
# => ["low_resolution", #<Hashie::Mash height=306 url="http://distilleryimage7.s3.amazonaws.com/1094f8968f6b11e38352122ed0b019ef_6.jpg" width=306>]
# >> ipics.first.images.standard_resolution
# => #<Hashie::Mash height=640 url="http://distilleryimage7.s3.amazonaws.com/1094f8968f6b11e38352122ed0b019ef_8.jpg" width=640>
# >> ipics.first.images.standard_resolution.url
# => "http://distilleryimage7.s3.amazonaws.com/1094f8968f6b11e38352122ed0b019ef_8.jpg"
# >> ipics.first.images.standard_resolution.width