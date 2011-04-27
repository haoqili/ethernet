# Copied from github.com/pwnall/ether_shell/lib/ether_shell/raw_socket.rb
# Basically the same to scratchpad's raw_ethernet
#   here and ether_shell = scratchpad's equivalent
#   eth_device = if_name
#   set_socket_eth_device() = set_socket_interface()
#   self.mac() = self.get_interface_mac()

require 'socket'

# :nodoc: namespace
module Ethernet # changed from EtherShell

# Low-level socket creation functionality.
module RawSocket
  # A raw socket will receive all Ethernet frames, and send raw frames.
  #
  # Args:
  # eth_device:: device name for the Ethernet card, e.g. 'eth0'
  # ether_type:: Ethernet protocol number
  def self.socket(eth_device = nil, ether_type = nil)
    ether_type ||= all_ethernet_protocols
    socket = Socket.new raw_address_family, Socket::SOCK_RAW, htons(ether_type)
    socket.setsockopt Socket::SOL_SOCKET, Socket::SO_BROADCAST, true
    set_socket_eth_device(socket, eth_device, ether_type) if eth_device
    socket
  end
  
  # The MAC address for an Ethernet card.
  #
  # Args:
  # eth_device:: device name for the Ethernet card, e.g. 'eth0'
  def self.mac(eth_device)
    case RUBY_PLATFORM
    when /linux/
      # /usr/include/net/if.h, structure ifreq
      ifreq = [eth_device].pack 'a32'
      # 0x8927 is SIOCGIFHWADDR in /usr/include/bits/ioctls.h
      socket.ioctl 0x8927, ifreq
      ifreq[18, 6] #in scratchpad's raw_ethernet, then says .unpack('H*').first
                   # because raw socket should return raw data
                   # leaving higher layers (like ping.rb) for presentation issues
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end

  class <<self
    # Sets the Ethernet interface and protocol type for a socket.
    def set_socket_eth_device(socket, eth_device, ether_type)
      case RUBY_PLATFORM
      when /linux/
        if_number = get_interface_number eth_device
        # struct sockaddr_ll in /usr/include/linux/if_packet.h
        socket_address = [raw_address_family, htons(ether_type), if_number,
                          0xFFFF, 0, 0, ""].pack 'SSISCCa8'
        socket.bind socket_address
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
      socket
    end
    private :set_socket_eth_device
    
    # The interface number for an Ethernet interface.
    def get_interface_number(eth_device)
      case RUBY_PLATFORM
      when /linux/
        # /usr/include/net/if.h, structure ifreq
        ifreq = [eth_device].pack 'a32'
        # 0x8933 is SIOCGIFINDEX in /usr/include/bits/ioctls.h
        socket.ioctl 0x8933, ifreq
        ifreq[16, 4].unpack('I').first
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
    end
    private :get_interface_number
    
    # The protocol number for listening to all ethernet protocols.
    def all_ethernet_protocols
      case RUBY_PLATFORM
      when /linux/
        3
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
    end
    private :all_ethernet_protocols
    
    # The AF / PF number for raw sockets.
    def raw_address_family
      case RUBY_PLATFORM
      when /linux/
        17 # cat /usr/include/bits/socket.h | grep PF_PACKET
      when /darwin/
        18 # cat /usr/include/sys/socket.h | grep AF_LINK
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
    end
    private :raw_address_family
  
    # Converts a 16-bit integer from host-order to network-order.
    def htons(short_integer)
      [short_integer].pack('n').unpack('S').first
    end
    private :htons
  end
end # module Ethernet::RawSocket

end # namespace Ethernet


