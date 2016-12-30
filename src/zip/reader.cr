require "zlib"
require "./file_info"

class Zip::Reader
  property? sync_close = false
  property? closed = false

  @last_entry : Entry?

  def initialize(@io : IO, @sync_close = false)
    @reached_end = false
  end

  def self.new(filename : String, sync_close = false)
    new(::File.new(filename), sync_close: sync_close)
  end

  def self.open(io_or_filename, sync_close = false)
    reader = new(io_or_filename, sync_close: sync_close)
    yield reader ensure reader.close
  end

  def next_entry
    return nil if @reached_end

    @last_entry.try &.close

    signature = @io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
    unless signature == FileInfo::SIGNATURE
      @reached_end = true
      return nil
    end

    @last_entry = Entry.new(@io)
  end

  def each_entry
    while entry = next_entry
      yield entry
    end
  end

  def close
    return if @closed
    @closed = true
    @io.close if @sync_close
  end

  class Entry
    include FileInfo

    getter io : IO
    getter? closed = false

    def initialize(io)
      super(io)

      io = IO::Sized.new(io, compressed_size)
      @io = decompressor_for(io)
    end

    def close
      return if @closed
      @closed = true
      @io.skip_to_end
    end
  end
end
