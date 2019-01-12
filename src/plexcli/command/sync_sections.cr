require "../server"
module PlexCLI
  module Command
    class SyncSections
      struct Metum
        property! :key
        property! :path
        property! :metum
        def initialize(@key : String, @path : String, @metum : JSON::Any)
        end
      end

      property! source : Server
      property! destination : Server
      property! section : String

      def initialize(@source, @destination, @section)
      end

      def run
        source_section = find_section source
        destination_section = find_section destination

        raise ArgumentError.new "Section does not exist on both servers" if source_section.nil? || destination_section.nil?

        left = media source, source_section
        right = media destination, destination_section

        left.each do |source_metum|
          # source_metum = left.first
          destination_metum = right.find { |metum| metum.path == source_metum.path }

          unless destination_metum.nil?
            left_tags = tags_for(source_metum)
            right_tags = tags_for(destination_metum)

            added = left_tags - right_tags
            removed = right_tags - left_tags

            if added.size > 0
              destination.set_collections destination_section["key"].as_s, destination_metum.key, destination_section["type"].as_s, added, false
            end

            if removed.size > 0
              destination.set_collections destination_section["key"].as_s, destination_metum.key, destination_section["type"].as_s, removed, true
            end

            values = {} of String => String

            %w{title rating userRating}.each do |key|
              if source_metum.metum[key]? != destination_metum.metum[key]?
                values["#{key}.value"] = source_metum.metum[key]?.to_s
                values["#{key}.locked"] = "1"
              end
            end

            unless values.empty?
              destination.set_media_metadata(destination_section["key"].as_s, destination_metum.key, destination_section["type"].as_s, values)
            end
          end
        end
      end

      def find_section(server : Server)
        sections = server.sections["MediaContainer"]
        if sections.nil? || sections["Directory"]?.nil?
          raise "No Sections Found"
        end

        sections["Directory"].as_a.find do |server_section|
          server_section["title"] == section
        end
      end

      def media(server : Server, section : JSON::Any)
        server.all_section_items(section["key"].as_s)["MediaContainer"]["Metadata"].as_a.map do |metum|
          Metum.new metum["ratingKey"].as_s, relative_path(section, metum), metum
        end
      end

      def relative_path(section : JSON::Any, metum : JSON::Any)
        locations = section["Location"].as_a.map { |location| location["path"].as_s }

        file = metum["Media"].as_a.first["Part"].as_a.first["file"].as_s

        location = locations.find { |l| file.starts_with?(l) }

        unless location.nil?
          file = file.lstrip(location)
        end

        file
      end

      def tags_for(metum : Metum)
        tags = [] of String
        collection = metum.metum["Collection"]?
        unless collection.nil?
          tags = collection.as_a.map do |tag|
            tag["tag"].as_s
          end.compact
        end
        tags
      end

    end
  end
end
