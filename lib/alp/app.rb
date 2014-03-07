require 'alp/message'
require 'alp/folder'
require 'alp/view'
require 'maildir'
require 'curses'

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
  class App
    def sanitize_filename(filename)
      filename.gsub /[^a-z0-9\-]+/i, '_'
    end

    def init
      Curses.init_screen
      Curses.cbreak
      Curses.noecho
      Curses.nonl
      Curses.stdscr.keypad(true)
      Curses.use_default_colors
      Curses.start_color
    end
 
    def deinit
      Curses.echo
      Curses.nocbreak
      Curses.nl
      Curses.close_screen
    end

    def run(path)
      begin
        init
       
        maxx = Curses.stdscr.maxx
       
        maxy = Curses.stdscr.maxy
       
        folder = Folder.new(path)

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
       
        Curses.clear

        while (running)
          Curses.attroff(Curses::A_BOLD)
          Curses.attron(Curses::A_REVERSE)
          Curses.setpos(0, 0)
          Curses.addstr " " * width
          Curses.setpos(0, 0)
          Curses.addstr "  #{folder.path}"
          message_text = "Message #{view.index + 1} of #{view.size}  "
          Curses.setpos(0, width - message_text.length)
          Curses.addstr message_text
          Curses.attroff(Curses::A_REVERSE)
       
          (0..height).each do |index|
            mail    = mails[view.offset + index]
            next unless mail
            date    = mail.date
            from    = mail.from[0, from_width]
            subject = mail.subject[0, subject_width]
            if view.position == index
              Curses.attron(Curses::A_REVERSE)
            else
              Curses.attroff(Curses::A_REVERSE)
            end
            if mail.flags.include? "S"
              Curses.attroff(Curses::A_BOLD)
              flags = " "
            else
              Curses.attron(Curses::A_BOLD)
              flags = "N"
            end
            if mail.flags.include? "R"
              flags = "A"
            end
            if mail.flags.include? "T"
              flags = "D"
            end
            Curses.setpos(start + index, 0)
            Curses.addstr " " * width
            Curses.setpos(start + index, flags_offset)   ; Curses.addstr flags
            Curses.setpos(start + index, from_offset)    ; Curses.addstr from
            Curses.setpos(start + index, subject_offset) ; Curses.addstr subject
            Curses.setpos(start + index, date_offset)    ; Curses.addstr sprintf("%*s", date_width, date.to_human_s)
          end
          Curses.refresh
          ch = Curses.getch
          case ch
          when ?q
            running = false
          when ?u
            include_seen = !include_seen
            mails = folder.messages(include_seen).map {|m| Message.new(m) }
            view = View.new width = maxx, height = maxy - start - 1, size = mails.length
          when Curses::Key::HOME
            view.home!
          when Curses::Key::END
            view.end!
          when Curses::Key::UP
            view.up!
          when Curses::Key::DOWN
            view.down!
          when Curses::Key::PPAGE
            view.page_up!
          when Curses::Key::NPAGE
            view.page_down!
          when Curses::Key::RESIZE
            maxx = Curses.stdscr.maxx
            maxy = Curses.stdscr.maxy
            view = View.new width = maxx, height = maxy - start - 1, size = mails.length
          when ?e
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
          when ?r
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
          when ?c
            message = Mail::Message.new
            File.open("mail", 'w') do |file|
              file.write(message.to_s)
            end
            deinit
            system "vi mail"
            init
          when ?n
            mail = mails[view.index].msg
            if mail.flags.include?("S")
              mail.remove_flag("S")
              mail.process
            else
              mail.process
              mail.add_flag("S")
            end
          when ?d
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
