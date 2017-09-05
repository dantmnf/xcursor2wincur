#encoding: utf-8
Cursor = Struct.new(:width, :height, :xhot, :yhot, :delay, :pixels, :tag)
class XcursorReader
  FileToc = Struct.new(:type, :subtype, :position) do
    def self.unpack(raw)
      self.new(*raw.unpack('L<3'))
    end
    def self.rawsize
      12
    end
  end
  ImageHeader = Struct.new(:header, :type, :nominalsize, :version,
                           :width, :height, :xhot, :yhot, :delay) do
    def self.unpack(raw)
      self.new(*raw.unpack('L<9'))
    end
    def self.rawsize
      36
    end
  end
  XCURSOR_COMMENT_TYPE = 0xfffe0001
  XCURSOR_IMAGE_TYPE = 0xfffd0002
  def self.read(io)
    header = io.read(16)
    magic, headerlen, version, ntoc = header.unpack('L<4')
    badfile = RuntimeError.new("bad Xcursor file")
    raise badfile if magic != 0x72756358 # Xcur
    raise badfile if headerlen != 16
    raise badfile if version != 0x00010000
    tocentries = ntoc.times.map do
      toc = io.read(12)
      FileToc.unpack(toc)
    end
    images = tocentries.select{|x| x.type == XCURSOR_IMAGE_TYPE }
    images.map! do |toc|
      io.seek(toc.position)
      rawheader = io.read(36)
      header = ImageHeader.unpack(rawheader)
      pixels = io.read(header.width*header.height*4)
      Cursor.new(header.width, header.height, header.xhot, header.yhot, header.delay, pixels, header.nominalsize)
    end
    images
  end
end