module Zip::FileInfo
  SIGNATURE = 0x04034b50
  STORED    =          0
  DEFLATED  =          8

  getter version : UInt16
  getter general_purpose_bit_flag : Int16
  getter compression_method : UInt16
  getter last_mod_file_time : Int16
  getter last_mod_file_date : Int16
  getter crc32 : Int32
  getter compressed_size : UInt32
  getter uncompressed_size : UInt32
  getter filename : String

  def initialize(io : IO)
    @version = read(io, UInt16)
    @general_purpose_bit_flag = read(io, Int16)
    @compression_method = read(io, UInt16)
    @last_mod_file_time = read(io, Int16)
    @last_mod_file_date = read(io, Int16)
    @crc32 = read(io, Int32)
    @compressed_size = read(io, UInt32)
    @uncompressed_size = read(io, UInt32)
    file_name_length = read(io, UInt16)
    extra_field_length = read(io, UInt16)
    @filename = io.read_string(file_name_length)
    io.skip(extra_field_length)
  end

  def dir?
    filename.ends_with?('/')
  end

  def file?
    !dir?
  end

  def decompressor_for(io)
    case compression_method
    when FileInfo::STORED
      io
    when FileInfo::DEFLATED
      Zlib::Inflate.new(io, wbits: Zlib::ZIP)
    else
      raise "Unsupported compression method: #{compression_method}"
    end
  end

  private def read(io, type)
    io.read_bytes(type, IO::ByteFormat::LittleEndian)
  end
end
