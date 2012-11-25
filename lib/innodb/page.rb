require "innodb/cursor"

class Innodb::Page
  # Currently only 16kB InnoDB pages are supported.
  PAGE_SIZE = 16384

  # InnoDB Page Type constants from include/fil0fil.h.
  PAGE_TYPE = {
    0     => :ALLOCATED,      # Freshly allocated page
    2     => :UNDO_LOG,       # Undo log page
    3     => :INODE,          # Index node
    4     => :IBUF_FREE_LIST, # Insert buffer free list
    5     => :IBUF_BITMAP,    # Insert buffer bitmap
    6     => :SYS,            # System page
    7     => :TRX_SYS,        # Transaction system data
    8     => :FSP_HDR,        # File space header
    9     => :XDES,           # Extent descriptor page
    10    => :BLOB,           # Uncompressed BLOB page
    11    => :ZBLOB,          # First compressed BLOB page
    12    => :ZBLOB2,         # Subsequent compressed BLOB page
    17855 => :INDEX,          # B-tree node
  }

  # A helper to convert "undefined" values stored in previous and next pointers
  # in the page header to nil.
  def self.maybe_undefined(value)
    value == 4294967295 ? nil : value
  end

  SPECIALIZED_CLASSES = {}

  def self.parse(buffer)
    page = Innodb::Page.new(buffer)

    if specialized_class = SPECIALIZED_CLASSES[page.type]
      page = specialized_class.new(buffer)
    end

    page
  end

  # Initialize a page by passing in a 16kB buffer containing the raw page
  # contents. Currently only 16kB pages are supported.
  def initialize(buffer)
    unless buffer.size == PAGE_SIZE
      raise "Page buffer provided was not #{PAGE_SIZE} bytes" 
    end

    @buffer = buffer
  end

  # A helper function to return bytes from the page buffer based on offset
  # and length, both in bytes.
  def data(offset, length)
    @buffer[offset...(offset + length)]
  end

  # Return an Innodb::Cursor object positioned at a specific offset.
  def cursor(offset)
    Innodb::Cursor.new(self, offset)
  end

  FIL_HEADER_SIZE   = 38
  FIL_HEADER_START  = 0
  FIL_HEADER_END    = FIL_HEADER_START + FIL_HEADER_SIZE

  # Return the "fil" header from the page, which is common for all page types.
  def fil_header
    c = cursor(FIL_HEADER_START)
    @fil_header ||= {
      :checksum   => c.get_uint32,
      :offset     => c.get_uint32,
      :prev       => Innodb::Page.maybe_undefined(c.get_uint32),
      :next       => Innodb::Page.maybe_undefined(c.get_uint32),
      :lsn        => c.get_uint64,
      :type       => PAGE_TYPE[c.get_uint16],
      :flush_lsn  => c.get_uint64,
      :space_id   => c.get_uint32,
    }
  end
  alias :fh :fil_header

  # A helper function to return the page type from the "fil" header, for easier
  # access.
  def type
    fil_header[:type]
  end

  # A helper function to return the page offset from the "fil" header, for
  # easier access.
  def offset
    fil_header[:offset]
  end

  # A helper function to return the page number of the logical previous page
  # (from the doubly-linked list from page to page) from the "fil" header,
  # for easier access.
  def prev
    fil_header[:prev]
  end

  # A helper function to return the page number of the logical next page
  # (from the doubly-linked list from page to page) from the "fil" header,
  # for easier access.
  def next
    fil_header[:next]
  end

  # Dump the contents of a page for debugging purposes.
  def dump
    puts
    puts "#{self}:"

    puts
    puts "fil header:"
    pp fil_header
  end
end
