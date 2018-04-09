require "../server"
module PlexCLI
  module Command
    class SyncPlaylists
      property! source : Server
      property! destination : Server

      def initialize(@source, @destination)
      end

      def run
        pairs
      end

      # Select pairs of playlists by title
      def pairs
        left = playlists_by_name(source)
        right = playlists_by_name(destination)

        # only operate on playlists which exist in each server
        playlist_names = left.keys & right.keys
        puts "Syncing #{playlist_names.size} playlists"

        destination_sections = destination.sections["MediaContainer"]["Directory"]
        playlist_names.each do |playlist_name|
          right_playlist_id = right[playlist_name]["ratingKey"].to_s
          l = source.playlist(left[playlist_name]["ratingKey"].to_s)["MediaContainer"]["Metadata"]
          r = destination.playlist(right_playlist_id)["MediaContainer"]["Metadata"]

          left_titles = l.map do |media|
            [media["title"]?, media["parentTitle"]?, media["grandparentTitle"]?]
          end
          right_titles = r.map do |media|
            [media["title"]?, media["parentTitle"]?, media["grandparentTitle"]?]
          end

          missing = left_titles - right_titles
          extra = right_titles - left_titles
          puts "\"#{playlist_name}\" delta: #{missing.size} added, #{extra.size} removed. Committing."

          missing.each do |item|
            response = destination.section_items(l.first["librarySectionID"].to_s, { "type" => "10", "X-Plex-Container-Start" => "0", "X-Plex-Container-Size" => "50", "title" => item.first.to_s })
            items = response["MediaContainer"]["Metadata"].select do |match|
              match["title"]? == item[0] && match["parentTitle"]? == item[1] && match["grandparentTitle"]? == item[2]
            end
            if items.size == 1
              item_id = items.first["ratingKey"]
              destination.add_playlist_item(right_playlist_id, "library://#{response["MediaContainer"]["librarySectionUUID"]}/item/%2Flibrary%2Fmetadata%2F#{item_id}")
            end
          end

          extra.each do |item|
            remove_list = r.select do |media|
              item == [media["title"]?, media["parentTitle"]?, media["grandparentTitle"]?]
            end
            remove_list.each do |item|
              destination.remove_playlist_item(right_playlist_id, item["playlistItemID"].to_s)
            end
          end


        end
      end

      def playlists_by_name(server : Server)
        server.playlists["MediaContainer"]["Metadata"].each_with_object({} of String => JSON::Any) do |playlist, memo|
          title = playlist["title"]
          unless title.nil?
            memo[title.to_s] = playlist
          end
        end
      end
    end
  end
end
