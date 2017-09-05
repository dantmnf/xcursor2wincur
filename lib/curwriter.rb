#encoding: utf-8
module WindowsCursorFileWriter
  module_function
  def get_data(cursors)
    icondir = [0, 2, cursors.length].pack('S<*')
    dataoffset = 6 + 16*cursors.length
    data = String.new
    # cursors.map{|x|  }
    entries = cursors.map do |x|
      raise 'image too large' if [x.width, x.height].max > 256
      bmp = get_dib_data(x.width, x.height, x.pixels)
      len = bmp.length
      entry = [
        x.width,
        x.height,
        0,
        0,
        x.xhot,
        x.yhot,
        len,
        dataoffset,
      ].pack('C4S<2L<2')
      dataoffset+=len
      data << bmp
      entry
    end.join(''.b)
    
    icondir + entries + data
  end

  def get_dib_data(width, height, pixels)
    bmp_pixels = "\x00".b * (width*height*4)
    line = width*4
    mask = []
    height.times do |y|
      linepx = pixels[y*line, line]
      bmp_pixels[(height-y-1)*line, line] = linepx
      linemask = bitfields linepx.unpack('L<*').map{|argb| ((argb>>24)&0xFF)==0 }
      if linemask.length % 4 != 0
        linemask << "\x00".b * (4 - linemask.length%4)
      end
      mask << linemask
    end
    mask.reverse!
    bmp_pixels << mask.join
    header = [
      40,                # DWORD biSize;
      width,              # LONG  biWidth;
      height*2,             # LONG  biHeight;
      1,                  # WORD  biPlanes;
      32,                 # WORD  biBitCount;
      0,                  # DWORD biCompression;
      bmp_pixels.length,  # DWORD biSizeImage;
      0,               # LONG  biXPelsPerMeter;
      0,               # LONG  biYPelsPerMeter;
      0,                  # DWORD biClrUsed;
      0,                  # DWORD biClrImportant;
      # 0x00FF0000,         # DWORD bV4RedMask;
      # 0x0000FF00,         # DWORD bV4GreenMask;
      # 0x000000FF,         # DWORD bV4BlueMask;
      # 0xFF000000,         # DWORD bV4AlphaMask;
      # 0x57696E20,         # DWORD bV4CSType;
    ].pack('L<3S<2L<*') #+
    # ([0x00]*0x24).pack('C*') +  # CIEXYZTRIPLE bV4Endpoints;
    # [
    #   0,                  # DWORD bV4GammaRed;
    #   0,                  # DWORD V4GammaGreen;
    #   0,                  # DWORD bV4GammaBlue;
    # ].pack('L<*')
    header + bmp_pixels
  end

  def bitfields(x)
    pos = 0
    dwords = x.each_slice(32).map do |s|
      dw = s.reduce(0) {|a,b| (a<<1) | (b ? 1 : 0) }
      dw = dw << 32 - s.length % 32 if s.length % 32 != 0
      dw
    end
    dwords.pack('L>*')[0..(x.length+7)/8]
  end
end