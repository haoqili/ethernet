#:%s/high_socket/socket_wrapper/gc # haoqi changed

# :nodoc: namespace

module Ethernet #from EtherShell

# Provides the Ethernet shell DSL.
#
# Include this in the evaluation context where you want the Ethernet shell DSL.
module ShellDsl
  # Creates a Ethernet socket for this shell.
  #
  # Args:
  #   eth_device:: an Ethernet device name, e.g. 'eth0'
  #   ether_type:: 2-byte Ethernet packet type number
  #   dest_mac:: MAC address of the endpoint to be tested; it can be a raw
  #              6-byte string, 
  def connect(eth_device, ether_type, dest_mac)
    raise "Already connected. did you forget to call disconnect?" if @_socket
    mac_bytes = Ethernet::ShellDsl.parse_mac_data dest_mac
    @_socket = Ethernet::SocketWrapper.new eth_device, ether_type
    @_socket.connect mac_bytes
    if @_verbose
      print ['Connected to ', mac_bytes.unpack('H*').first, ' using ',
             '%04x' % ether_type, ' via ', eth_device, "\n"].join
    end
    @_nothing = ''
    class <<@_nothing
      def inspect
        ''
      end
    end
    Ethernet::ShellDsl.nothing
  end

  # Disconnects this shell's Ethernet socket.
  #
  # A socket should have been connected previously, using connect or socket. The
  # shell can take further connect and socket calls.
  def disconnect
    raise "Not connected. did you forget to call connect?" unless @_socket
    @_socket.close
    @_socket = nil
    print "Disconnected\n" if @_verbose
    Ethernet::ShellDsl.nothing
  end
  
  # Connects this shell to a pre-created socket
  #
  # Args:
  #   socket_wrapper:: socket that behaves like an Ethernet::SocketWrapper
  def socket(socket_wrapper)
    raise "Already connected. did you forget to call disconnect?" if @_socket
    @_socket = socket_wrapper
    print "Connected directly to socket\n" if @_verbose
    Ethernet::ShellDsl.nothing
  end
  
  # Enables or disables the console output in out and expect.
  #
  # Args:
  #   true_or_false:: if true, out and expect will produce console output
  def verbose(true_or_false = true)
    @_verbose = true_or_false
    Ethernet::ShellDsl.nothing
  end
  
  # Outputs a packet.
  #
  # Args:
  #   packet_data:: an Array of integers (bytes), a hex string starting with 0x,
  #                 or a string of raw bytes
  #
  # Raises:
  #   RuntimeError:: if the shell was not connected to a socket by a call to
  #                  connect or socket
  def out(packet_data)
    raise "Not connected. did you forget to call connect?" unless @_socket
    bytes = Ethernet::ShellDsl.parse_packet_data packet_data
    
    
    print "Sending #{bytes.unpack('H*').first}... " if @_verbose
    @_socket.send bytes
    print "OK\n" if @_verbose
    Ethernet::ShellDsl.nothing
  end
  
  # Receives a packet and matches it against an expected value.
  #
  # Args:
  #   packet_data:: an Array of integers (bytes), a hex string starting with 0x,
  #                 or a string of raw bytes
  #
  # Raises:
  #   RuntimeError:: if the shell was not connected to a socket by a call to
  #                  connect or socket
  #   RuntimeError:: if the received packet doesn't match the expected value
  def expect(packet_data)
    raise "Not connected. did you forget to call connect?" unless @_socket
    expected_bytes = Ethernet::ShellDsl.parse_packet_data packet_data
    
    print "Receiving... " if @_verbose
    bytes = @_socket.recv
    print " #{bytes.unpack('H*').first} " if @_verbose
    if bytes == expected_bytes
      print "OK\n" if @_verbose
    else
      print "!= #{expected_bytes.unpack('H*').first} ERROR\n" if @_verbose
      raise Ethernet::ExpectationError,
          "#{bytes.unpack('H*').first} != #{expected_bytes.unpack('H*').first}"
    end
    Ethernet::ShellDsl.nothing
  end
  
  # :nodoc: turns a packet pattern into a string of raw bytes
  def self.parse_packet_data(packet_data)
    if packet_data.kind_of? Array
      # Array of integers.
      packet_data.pack('C*')
    elsif packet_data.kind_of? String
      if packet_data[0, 2] == '0x'
        [packet_data[2..-1]].pack('H*')
      else
        packet_data
      end
    end
  end

  # :nodoc: turns a packet pattern into a string of raw bytes
  def self.parse_mac_data(mac_data)
    if mac_data.length == 12
      [mac_data].pack('H*')
    elsif mac_data.length == 14 && mac_data[0, 2] == '0x'
      [mac_data[2, 12]].pack('H*')
    elsif mac_data.kind_of? Array
      mac_data.pack('C*')
    else
      mac_data
    end
  end
  
  # :nodoc: value that doesn't show up in irb
  def self.nothing
    @nothing ||= Nothing.new
  end
  
  class Nothing
    def inspect
      ''
    end
  end
end  # module Ethernet::ShellDsl

end  # namespace Ethernet
