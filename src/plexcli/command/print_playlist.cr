require "../server"
module PlexCLI
  module Command
    class PrintPlaylist
      property! source : Server
      property! name : String

      def initialize(@source, @name)
      end

      def run
        playlists = playlists_by_name(source)
        playlist = playlists[name]?

        if playlist.nil?
          raise ArgumentError.new("no such playlist found")
        else
          items = source.playlist(playlist["ratingKey"].to_s)

          unless items.nil? || items["MediaContainer"]?.nil? || items["MediaContainer"]["Metadata"]?.nil?
            items["MediaContainer"]["Metadata"].as_a.each do |item|
              item["Media"].as_a.each do |media|
                media["Part"].as_a.each do |part|
                  puts part["file"]
                end
              end
            end
          end
        end
      end

      def playlists_by_name(server : Server)
        server.playlists["MediaContainer"]["Metadata"].as_a.each_with_object({} of String => JSON::Any) do |playlist, memo|
          title = playlist["title"]
          unless title.nil?
            memo[title.to_s] = playlist
          end
        end
      end
    end
  end
end
