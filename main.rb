require 'httparty'
require 'nokogiri'
require 'uri'
require 'sinatra'
require 'pp'

# todo handling multiple albums per review page
# todo print top track(s) from each album, and overall top 5 tracks
# todo link to their top youtube video


get '/' do
  erb :index
end

get '/search/:artist' do
  artist = params[:artist].chomp(" ")
  artist.gsub!("’", "'")
  artist.split(",").first
  artist.chomp!(" ")
  r = HTTParty.get ("https://pitchfork.com/search/more/?query=#{URI::encode artist}&filter=albumreviews")
  resp = Nokogiri::HTML r

  albums = []

  resp.css(".review").each do |rev|
    # Filter out the crap
    found_artist = rev.css(".review__title-artist").first.text
    found_artist.gsub!("’", "'")
    next unless found_artist.downcase == artist.downcase
    album_url = rev.css(".review__link").first['href']
    album_name = rev.css(".review__title-album").first.text
    if album_url.end_with?("-ep/")
      next
    end

    # Let's now load the album and build our hash
    review_html = Nokogiri::HTML HTTParty.get("https://pitchfork.com#{album_url}")
    review_score = review_html.css(".score").first.text.to_f
    albums << {name: album_name, score: review_score, url: "https://pitchfork.com#{album_url}"}
  end

  if albums.size > 0
    scores = albums.collect{|a| a[:score]}
    sum = scores.inject(0) {|sum, i|  sum + i }
    avg = (sum / scores.size).round(2)
    html = ""

    html += "#{artist.capitalize} report card (#{avg}) "
    html += "**PITCHFORK APPROVED**" if avg >= 7.5
    html += "<br>-------------------------------<br>"
    html += "Newest: <a target='_blank' href='#{albums.first[:url]}'>#{albums.first[:name]}</a> - #{albums.first[:score]}<br><br>"
    html += "All albums:<br>"
    albums.sort_by{|r| r[:score]}.reverse.each{|a| html +=  "<a target='_blank' href='#{a[:url]}'>#{a[:name]}</a> - #{a[:score]}<br>"}

    html
  else
    "No results"
  end
end


