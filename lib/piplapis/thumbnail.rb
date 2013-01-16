# coding: UTF-8

module PiplApi

# Ruby wrapper for Pipl's Thumbnail API.
# 
# Pipl's thumbnail API provides a thumbnailing service for presenting images in 
# your application. The images can be from the results you got from our Search
# API but it can also be any web URI of an image.
# 
# The thumbnails returned by the API are in the height/width defined in the 
# request. Additional features of the API are:
# - Detect and Zoom-in on human faces (in case there's a human face in the image).
# - Optionally adding to the thumbnail the favicon of the website where the image 
#   is from (for attribution, recommended for copyright reasons).
# 
# This module contains only one function - generate_thumbnail_url() that can be 
# used for transforming an image URL into a thumbnail API URL.

require 'uri'
require_relative 'data/utils'
require_relative 'data/fields'

THUMB_BASE_URL = 'http://api.pipl.com/thumbnail/v2/?'
THUMB_MAX_PIXELS = 500

module ThumbnailApi
    # Default API key value, you can set your key globally in this variable instead 
    # of passing it in each API call
    @@default_api_key = nil
    
    def self.default_api_key
        @@default_api_key
    end
    
    def self.default_api_key=key
        @@default_api_key = key
    end
end

def self.generate_thumbnail_url(params={})
    # Take an image URL and generate a thumbnail URL for that image.
    # 
    # Args:
    # 
    # image_url -- unicode (utf8 encoded str), URL of the image you want to 
    #              thumbnail.   
    # height -- int, requested thumbnail height in pixels, maximum 500.
    # width -- int, requested thumbnail width in pixels, maximum 500.
    # favicon_domain -- unicode (utf8 encoded str), optional, the domain of 
    #                   the website where the image came from, the favicon will 
    #                   be added to the corner of the thumbnail, recommended for 
    #                   copyright reasones.
    #                   IMPORTANT: Don't assume that the domain of the website is
    #                   the domain from `image_url`, it's possible that 
    #                   domain1.com hosts its images on domain2.com.
    # zoom_face -- bool, indicates whether you want the thumbnail to zoom on the 
    #              face in the image (in case there is a face) or not.
    # api_key -- str, a valid API key (use "samplekey" for experimenting).
    # 
    # ArgumentError is raised in case of illegal parameters.
    # 
    # Example (thumbnail URL from an image URL):
    # 
    # require 'thumbnail'
    # image_url = 'http://a7.twimg.com/a/ab76f.jpg'
    # PiplApi::generate_thumbnail_url({ :image_url => image_url,
    #                                               :height => 100,
    #                                               :width => 100, 
    #                                               :favicon_domain => 'twitter.com',
    #                                               :api_key => 'samplekey' })
    # => "http://api.pipl.com/thumbnail/v2/?key=samplekey&image_url=http%3A%2F%2Fa7.t
    # wimg.com%2Fa%2Fab76f.jpg&height=100&width=100&favicon_domain=twitter.com&zoom_fa
    # ce=true"
    # 
    # Example (thumbnail URL from a record that came in the response of our 
    # Search API):
    # 
    # require 'thumbnail'
    # PiplApi::generate_thumbnail_url({ :image_url => record.images[0].url,
    #                                               :height => 100,
    #                                               :width => 100, 
    #                                               :favicon_domain => record.source.domain,
    #                                               :api_key => 'samplekey' })

    fparams = { :zoom_face => true }.merge(params)
    
    if fparams[:image_url].nil? or fparams[:width].nil? or fparams[:height].nil?
        raise ArgumentError, "Some parameters are missing!"
    end
    
    key = fparams[:api_key] || ThumbnailApi.default_api_key
    image_url = fparams[:image_url]
    width = fparams[:width]
    height = fparams[:height]
    favicon_domain = fparams[:favicon_domain]
    zoom_face = fparams[:zoom_face]

    if key.nil?
        raise ArgumentError, 'A valid API key is required'
    end
    
    if not(Image.new({:url=>image_url}).is_valid_url?)
        raise ArgumentError, 'image_url is not a valid URL'
    end

    if not((1..THUMB_MAX_PIXELS).member?(height) and (1..THUMB_MAX_PIXELS).member?(width))
        raise ArgumentError, 'height/width must be between 1 and #{THUMB_MAX_PIXELS}'
    end
    
    query = {
        'key' => PiplApi::to_utf8(key),
        'image_url' => URI.unescape(PiplApi::to_utf8(image_url)),
        'height' => height,
        'width' => width,
        'favicon_domain' => PiplApi::to_utf8(favicon_domain || ''),
        'zoom_face' => zoom_face
    }
    THUMB_BASE_URL + URI.encode_www_form(query)
end

end
