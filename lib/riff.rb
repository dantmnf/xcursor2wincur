#encoding: utf-8
module RIFF
  class Chunk
    attr_accessor :id, :data
    def initialize(id, data)
      @id=id
      @data=data
    end
    def to_s
      realdata = data
      result = [@id, realdata.length, realdata].pack('A4L<A*')
      result << "\x00".b if result.length.odd?
      result
    end
  end

  class DirectoryChunk < Chunk
    attr_accessor :subchunks
    def initialize(id, type)
      super(id, [type].pack('A4'))
      @subchunks = []
    end
    
    def data
      subchunks_data = @subchunks.map(&:to_s).join
      @data + subchunks_data
    end
  end
end