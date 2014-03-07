require 'maildir'

module Alp
  class Folder
    attr_reader :path

    def initialize path
      @path = path
    end

    def messages include_seen
      maildir = Maildir.new(path, false)

      mails = maildir.list(:new) + maildir.list(:cur)

      mails.select! {|a|
        result = if a.flags.include? "S"
          include_seen
        else
         true
        end
        result && !a.flags.include?("T")
      }

      mails.sort! {|a, b| b.unique_name <=> a.unique_name }

      mails
    end
  end
end
