module Alp
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
end
