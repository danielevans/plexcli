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


    def all_section_items(id : String)
      query = params
      query["type"] = "1"
      query["includeCollection"] = "1"
      query["X-Plex-Container-Start"] = "0"
      query["X-Plex-Container-Size"] = "1000000"
      response = connection.get "/library/sections/#{id}/all", headers, query.to_s
      JSON.parse(response.body)
    end


    def set_collections(section_id : String, id : String, media_type : String, tags : Array(String), remove : Bool = false)
      query_params = params
      query_params["id"] = id
      query_params["type"] = self.class.media_type(media_type).to_s

      # tag_params = HTTP::Params.new
      if remove
        query_params["collection[].tag.tag-"] = tags.join(",")
      else
        tags.each_with_index do |tag, i|
          key = "collection[#{i}].tag.tag"
          query_params[key] = tag
        end
      end
      response = connection.put "/library/sections/#{section_id}/all?#{query_params.to_s}", headers
    end


    def set_media_metadata(section_id : String, id : String, media_type : String, metadata : Hash(String, String))
      query_params = params
      query_params["id"] = id
      query_params["type"] = self.class.media_type(media_type).to_s

      metadata.each_key do |key|
        query_params[key] = metadata[key]
      end

      response = connection.put "/library/sections/#{section_id}/all?#{query_params.to_s}", headers
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

    def self.media_type(t : String)
      {
        "movie" => 1,
        "show" => 2,
        "season" => 3,
        "episode" => 4,
        "trailer" => 5,
        "comic" => 6,
        "person" => 7,
        "artist" => 8,
        "album" => 9,
        "track" => 10,
        "photoAlbum" => 11,
        "picture" => 12,
        "photo" => 13,
        "clip" => 14,
        "playlistItem" => 15,
        "playlistFolder"=> 16,
        "collection"=> 18,
        "userPlaylistItem"=> 1001
      }[t]
    end
  end
end
