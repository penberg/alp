require 'ncursesw'
require 'maildir'
require 'mail'
require 'time'

class Time
  def to_human_s from = Time.now
    if year != from.year
      strftime("%d/%m/%Y")
    elsif month != from.month
      strftime("%e %b")
    else
      if day == from.day
        strftime("%H:%M")
      else
        strftime("%e %b")
      end
    end
  end
end

module Alp
  class Folder
    attr_reader :name

    def initialize name
      @name = name
    end

    def messages include_seen
      home = ENV['HOME']

      maildir = Maildir.new("#{home}/Mail/#{@name}", false)

      mails = maildir.list(:new) + maildir.list(:cur)

      mails.select! {|a|
        result = if a.flags.include? "S"
          include_seen
        else
         true
        end
        result && !a.flags.include?("T")
      }

      mails.sort! {|a, b| File.basename(b.key) <=> File.basename(a.key) }

      mails
    end
  end

  class Message
    attr_reader :msg, :date, :from, :subject

    def initialize msg
      @msg     = msg
      lines    = msg.data.lines
      @date    = parse_date(lines)
      @from    = parse_from(lines)
      @subject = parse_subject(lines)
    end

    def flags
      @msg.flags
    end

    def parse_date(mail)
      result = mail.select {|line| line[/^Date:/]}[0]
      Time.parse(result[6..-1].strip)
    end

    def parse_from(mail)
      from = mail.select {|line| line[/^From:/]}[0]
      return "" unless from
      from = from[6..-1].strip
      name = from.match("(.+) <(.+?)@(.+)>")
      result = name && name[1] || from
      Mail::Encodings::value_decode(result).tr_s("\"", "").strip
    end

    def parse_subject(mail)
      result = mail.select {|line| line[/^Subject:/]}[0]
      return "" unless result
      Mail::Encodings::value_decode(result[9..-1].strip)
    end
  end

  class View
    attr_reader :position, :offset, :size

    def initialize width, height, size
      @width  = width
      @height = [height, size].min
      @size   = size
      @position, @offset = 0, 0
    end

    def index
      @offset + @position
    end

    def up!
      if @position > 0
        @position -= 1
      elsif @offset > 0
        @offset -= 1
      end
    end

    def down!
      if @position < @height
        @position += 1
      elsif @position + @offset < @size - 1
        @offset += 1
      end
    end

    def page_up!
      @offset -= @height
      home! if @offset < 0
    end

    def page_down!
      if @offset + @position + @height < @size
        @offset += @height
      else
        end!
      end
    end

    def home!
      @position, @offset = 0, 0
    end

    def end!
      if @size - @offset + @position < @height
        @position = @size - @offset - 1
      else
        @position = @height
        @offset   = @size - @height - 1
      end
    end
  end

  class App
    def sanitize_filename(filename)
      filename.gsub /[^a-z0-9\-]+/i, '_'
    end

    def init
      Ncurses.cbreak
      Ncurses.noecho
      Ncurses.nonl
      Ncurses.stdscr.intrflush(false)
      Ncurses.stdscr.keypad(true)
      Ncurses.use_default_colors
      Ncurses.start_color
    end
 
    def deinit
      Ncurses.echo
      Ncurses.nocbreak
      Ncurses.nl
      Ncurses.endwin
    end
 
    def run
      begin
        Ncurses.initscr
       
        init
       
        maxx = Ncurses.getmaxx(Ncurses.stdscr)
       
        maxy = Ncurses.getmaxy(Ncurses.stdscr)
       
        folder = Folder.new "INBOX"

        include_seen = true
       
        mails = folder.messages(include_seen).map {|m| Message.new(m) }
       
        start    = 2
        width    = maxx
        height   = maxy - start - 1
        running  = true
       
        flags_width   = 1
        from_width    = width / 5
        date_width    = 10
        subject_width = width - 1 - flags_width - 2 - from_width - 2 - 2 - date_width - 1
       
        flags_offset   = 1
        from_offset    = flags_offset + flags_width + 2
        subject_offset = from_offset + from_width + 2
        date_offset    = subject_offset + subject_width + 2
       
        view = View.new width = maxx, height = maxy - start - 1, size = mails.length
       
        while (running)
          Ncurses.erase
       
          Ncurses.attroff(Ncurses::A_BOLD)
          Ncurses.attron(Ncurses::A_REVERSE)
          Ncurses.stdscr.move(0, 0)
          Ncurses.stdscr.addstr " " * width
          Ncurses.stdscr.move(0, 0)
          Ncurses.stdscr.addstr "  #{folder.name}"
          message_text = "Message #{view.index + 1} of #{view.size}  "
          Ncurses.stdscr.move(0, width - message_text.length)
          Ncurses.stdscr.addstr message_text
          Ncurses.attroff(Ncurses::A_REVERSE)
       
          (0..height).each do |index|
            mail    = mails[view.offset + index]
            next unless mail
            date    = mail.date
            from    = mail.from[0, from_width]
            subject = mail.subject[0, subject_width]
            if view.position == index
              Ncurses.attron(Ncurses::A_REVERSE)
            else
              Ncurses.attroff(Ncurses::A_REVERSE)
            end
            if mail.flags.include? "S"
              Ncurses.attroff(Ncurses::A_BOLD)
              flags = " "
            else
              Ncurses.attron(Ncurses::A_BOLD)
              flags = "N"
            end
            if mail.flags.include? "R"
              flags = "A"
            end
            if mail.flags.include? "T"
              flags = "D"
            end
            Ncurses.stdscr.move(start + index, 0)
            Ncurses.stdscr.addstr " " * width
            Ncurses.stdscr.move(start + index, flags_offset)   ; Ncurses.stdscr.addstr flags
            Ncurses.stdscr.move(start + index, from_offset)    ; Ncurses.stdscr.addstr from
            Ncurses.stdscr.move(start + index, subject_offset) ; Ncurses.stdscr.addstr subject
            Ncurses.stdscr.move(start + index, date_offset)    ; Ncurses.stdscr.addstr sprintf("%*s", date_width, date.to_human_s)
          end
          ch = Ncurses.stdscr.getch
          case ch
          when 'q'.ord
            running = false
          when 'n'.ord
            include_seen = !include_seen
            mails = folder.messages(include_seen).map {|m| Message.new(m) }
            view = View.new width = maxx, height = maxy - start - 1, size = mails.length
          when Ncurses::KEY_HOME
            view.home!
          when Ncurses::KEY_END
            view.end!
          when Ncurses::KEY_UP
            view.up!
          when Ncurses::KEY_DOWN
            view.down!
          when Ncurses::KEY_PPAGE
            view.page_up!
          when Ncurses::KEY_NPAGE
            view.page_down!
          when Ncurses::KEY_RESIZE
            maxx = Ncurses.getmaxx(Ncurses.stdscr)
            maxy = Ncurses.getmaxy(Ncurses.stdscr)
            view = View.new width = maxx, height = maxy - start - 1, size = mails.length
          when 'e'.ord
            mail    = mails[view.index]
            subject = mail.subject
            target  = sanitize_filename(subject)
            system "cp #{mail.msg.path} #{target}"
          when 13
            mail = mails[view.index].msg
            mail.process
            mail.add_flag("S")
            deinit
            system "less #{mail.path}"
            init
          when 'r'.ord
            mail = mails[view.index].msg
            message = Mail::Message.new(mail.data)
            reply = message.reply do
              body message.body.to_s.gsub(/^/, "> ")
            end
            reply.cc = message.cc
            File.open("mail", 'w') do |file|
              file.write(reply.to_s)
            end
            deinit
            system "vi mail"
            init
          when 'c'.ord
            message = Mail::Message.new
            File.open("mail", 'w') do |file|
              file.write(message.to_s)
            end
            deinit
            system "vi mail"
            init
          when 'u'.ord
            mail = mails[view.index].msg
            mail.process
            mail.remove_flag("S")
          when 'd'.ord
            mail = mails[view.index].msg
            mail.process
            mail.add_flag("T")
          end
        end
      ensure
        deinit
      end
    end
  end
end
