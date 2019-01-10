require "../server"
module PlexCLI
  module Command
    class ListSections
      property! server : Server

      def initialize(@server)
      end

      def run
        sections = server.sections["MediaContainer"]
        if sections.nil? || sections["Directory"]?.nil?
          puts "No Sections Found"
        else
          sections["Directory"].as_a.each do |section|
            puts "\"#{section["title"]?}\" (#{section["type"]?} #{section["uuid"]?})"
          end
        end
      end
    end
  end
end
