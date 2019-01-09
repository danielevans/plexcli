require "../server"
module PlexCLI
  module Command
    class ListPlaylists
      property! server : Server

      def initialize(@server)
      end

      def run
        playlists = server.playlists["MediaContainer"]?
        if playlists.nil? || playlists["Metadata"]?.nil?
          puts "No Playlists Found"
        else
          playlists["Metadata"].as_a.each do |playlist|
            puts "\"#{playlist["title"]?}\" (#{playlist["leafCount"]?} #{playlist["playlistType"]?} items)"
          end
        end
      end
    end
  end
end
