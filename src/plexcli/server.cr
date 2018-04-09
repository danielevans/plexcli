require "http/client"
require "http/headers"
require "json"

module PlexCLI
  class Server
    getter uri : URI
    getter token : String
    getter connection : HTTP::Client

    def initialize(@uri, @token)
      @connection = HTTP::Client.new @uri
      # @connection.before_request do |request|
      #   puts "#{request.method}: #{request.host}:#{request.path}/#{request.query} \"#{request.body}\""
      # end
    end

    def system
      response = connection.get "/", headers, params.to_s
      JSON.parse(response.body)
    end

    def playlists
      playlist_params = params
      playlist_params["type"] = "15"
      playlist_params["playlistType"] = "audio%2Cvideo"
      response = connection.get "/playlists", headers, playlist_params.to_s
      JSON.parse(response.body)
    end

    def playlist(id : String)
      response = connection.get "/playlists/#{id}/items", headers, params.to_s
      JSON.parse(response.body)
    end

    def add_playlist_item(playlist_id : String, item_uri : String)
      item_params = params
      item_params["uri"] = item_uri
      response = connection.put "/playlists/#{playlist_id}/items?#{item_params.to_s}", headers
    end

    def remove_playlist_item(playlist_id : String, item_id : String)
      response = connection.delete "/playlists/#{playlist_id}/items/#{item_id}?#{params.to_s}", headers
    end


    def sections
      response = connection.get "/library/sections", headers, params.to_s
      JSON.parse(response.body)
    end

    def section(id : String)
      response = connection.get "/library/sections/#{id}/", headers, params.to_s
      JSON.parse(response.body)
    end

    def section_items(id : String, query : Hash(String, String) = {} of String => String)
      items_params = params
      query.each do |key, value|
        items_params[key] = value
      end
      response = connection.get "/library/sections/#{id}/all?#{items_params.to_s}", headers
      JSON.parse(response.body)
    end



    def params
      HTTP::Params.new({
                         "X-Plex-Token" => [@token],
                         "Accept" => ["application/json"]
                       })
    end

    def headers
      HTTP::Headers.new.tap do |h|
        h["X-Plex-Token"] = @token
        h["Accept"] = ["application/json"]
      end
    end
  end
end
