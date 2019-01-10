require "http/headers"
require "http/params"
require "option_parser"
require "./plexcli/*"
require "./plexcli/command/*"

module PlexCLI
  def self.parse
    options = @@options = { :token => ENV["X-Plex-Token"]? } of Symbol => String | Nil
    OptionParser.parse! do |parser|
      parser.banner = "Usage: plexcli command [arguments]\ncommands: help, h, ls, list_playlists, sync_playlists, print_playlist, list_sections, print_section"
      parser.on("-s SERVER", "--server=SERVER", "server url") { |server| options[:server] = server }
      parser.on("-d SERVER", "--destination-server=SERVER", "server 2 url") { |server| options[:server2] = server }
      parser.on("-p TOKEN", "--plex-token TOKEN", "Plex authentication token") { |token| options[:token] = token }
      parser.on("-l LIST", "--playlist LIST", "Playlist Name") { |list| options[:playlist] = list }
      parser.on("-e", "--section SECTION", "Section Name") { |section| options[:section] = section }
      parser.on("-h", "--help") { options[:command] = "help" }
      parser.unknown_args do |argv|
        options[:command] = argv.first?
      end
    end
  end

  def self.run
    parser = parse
    options = @@options
    return if options.nil?
    if options[:command] == nil || options[:command] == ""
      raise ArgumentError.new "Command cannot be blank"
    end

    token = options[:token] || ""

    case options[:command]
    when "help", "h"
      puts parser.to_s
    when "ls"
      [options[:server]?, options[:server2]?].compact.each do |uri|
        server = Server.new URI.parse(uri), token
        puts server.system.to_pretty_json
      end
    when "list_playlists"
      uri = options[:server]
      unless uri.nil?
        command = Command::ListPlaylists.new  Server.new(URI.parse(uri), token)
        command.run
      end
    when "sync_playlists"
      uri = options[:server]
      uri2 = options[:server2]
      unless uri.nil? || uri2.nil?
        command = Command::SyncPlaylists.new  Server.new(URI.parse(uri), token), Server.new(URI.parse(uri2), token)
        command.run
      end
    when "print_playlist"
      uri = options[:server]
      list = options[:playlist]
      unless uri.nil? || list.nil?
        command = Command::PrintPlaylist.new  Server.new(URI.parse(uri), token), list
        command.run
      end

    when "list_sections"
      uri = options[:server]
      unless uri.nil?
        command = Command::ListSections.new  Server.new(URI.parse(uri), token)
        command.run
      end
    when "print_section"
      uri = options[:server]
      section = options[:section]
      unless uri.nil? || section.nil?
        command = Command::ListTags.new  Server.new(URI.parse(uri), token), section
        command.run
      end
    when "sync_sections"
      uri = options[:server]
      uri2 = options[:server2]
      section = options[:section]
      unless uri.nil? || uri2.nil?
        server1 = Server.new(URI.parse(uri), token)
        server2 = Server.new(URI.parse(uri2), token)
        command = Command::SyncSections.new server1, server2, section
        command.run
      end
    else
      puts "Unkown Command: #{options[:command]}"
      puts parser.to_s
    end
  end

  def self.print
    puts @@options
  end
end

PlexCLI.run
