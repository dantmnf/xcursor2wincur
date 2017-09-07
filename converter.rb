#!/usr/bin/env ruby
#encoding: utf-8
require_relative 'lib/XcursorReader'
require_relative 'lib/curwriter'
require_relative 'lib/riff'
def convert(filename)
  file = open(filename, 'rb')
  curs=XcursorReader.read(file)
  grps = curs.group_by{|x| x.tag}
  if grps.values.map{|x| x.length }.uniq.length != 1
    raise 'different frame count for different size is unsupported'
  end
  frames = grps.values.first.length
  if frames == 1
    curfile = WindowsCursorFileWriter.get_data(curs)
    puts "writing #{filename}.cur"
    IO.binwrite(filename+'.cur',curfile)
  else
    # animated, Xcursor groups by size, Windows ANI groups by frame
    curframes = frames.times.map{|i| grps.values.map{|x| x[i]}}
    if curframes.any? {|f| f.map{|c| c.delay}.uniq.length != 1}
      raise 'different delay for different size is unsupported'
    end
    uniq_jiffies = nil
    jiffies = []
    if (delay = curframes.map{|x|x.first.delay}.uniq).length == 1
      delay = delay[0]
      uniq_jiffies = (delay/(1000.0/60)).ceil
    end
    riff = RIFF::DirectoryChunk.new('RIFF', 'ACON')
    header = [
      36,
      frames,
      frames,
      0,
      0,
      32,
      1,
      uniq_jiffies || 1,
      1
    ].pack('L<*')
    anih = RIFF::Chunk.new('anih', header)
    riff.subchunks << anih
    fram = RIFF::DirectoryChunk.new('LIST', 'fram')
    fram.subchunks = curframes.map do |curframe|
      RIFF::Chunk.new('icon', WindowsCursorFileWriter.get_data(curframe))
    end
    riff.subchunks << fram
    unless uniq_jiffies
      jiffies = curframes.map{|x|(x.first.delay/(1000.0/60)).ceil}.pack('L<*')
      rate = RIFF::Chunk.new('rate', jiffies)
      riff.subchunks << rate
    end
    puts "writing #{filename}.ani, jiffies = #{(uniq_jiffies || jiffies).inspect}"
    IO.binwrite(filename+'.ani',riff.to_s)
  end
end

if ARGV.length == 0
  puts "usage: #$0 files ..."
end

ARGV.each {|x| convert x rescue puts "failed converting #{x}: #{$!.message}" }
