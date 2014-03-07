require 'mail'
require 'time'

module Alp
  class Message
    attr_reader :msg

    def initialize msg
      @msg = msg
    end

    def flags
      @msg.flags
    end

    def date
      result = @msg.data.scan(/^(Date):\s([^\r\n]+)/mx)
      return Time.parse(result[0][1])
    end

    def from
      result = @msg.data.scan(/^(From):\s([^\r\n]+)/mx)
      return "" unless result && result[0]
      from = result[0][1]
      name = from.match("(.+) <(.+?)@(.+)>")
      result = name && name[1] || from
      Mail::Encodings::value_decode(result).tr_s("\"", "").strip
      return result
    end

    def subject
      result = @msg.data.scan(/^(Subject):\s([^\r\n]+)/mx)
      return "" unless result && result[0]
      return result[0][1]
    end
  end
end
