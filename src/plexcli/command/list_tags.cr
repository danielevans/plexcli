require "../server"
module PlexCLI
  module Command
    class ListTags
      property! server : Server
      property! name : String

      def initialize(@server, @name)
      end

      def run
        section = server.sections["MediaContainer"]["Directory"].as_a.find do |section|
          section["title"] == self.name
        end
        unless section.nil?
          media = server.all_section_items(section["key"].to_s)["MediaContainer"]["Metadata"].as_a

          media.each do |medium|
            if medium.as_h.has_key? "Collection"
              tags = medium["Collection"].as_a.reduce([] of String) do |memo, collection|
                memo << collection["tag"].as_s unless collection["tag"].nil?
                memo
              end.join(", ")
              puts "#{medium["title"]?} (#{tags})"
            end
          end

        end
      end
    end
  end
end
