# copied from victor's scratchpad/lib/scratchpad/ethernet/ping.rb
# changes see raw_socket.rb
# :%s/if_name/eth_device/g
# .get_interface_mac() --> .mac()
# Ethernet.socket --> Ethernet::RawSocket.socket
# Ethernet.mac --> Ethernet::RawSocket.mac

# :nodoc: namespace # module Scratchpad

# :nodoc: namespace
module Ethernet

# Responder for ping utility using raw Ethernet sockets.
class PingServer
  module Connection
    def receive_data(packet)
      source_mac = packet[0, 6].unpack('H*')
      dest_mac = packet[6, 6].unpack('H*')
      ether_type = packet[12, 2].unpack('H*')
      
      puts "Src: #{source_mac} Dst: #{dest_mac} Eth: #{ether_type}\n"
      puts packet[14..-1].unpack('H*')
      
      # Exchange the source and destination ARP addresses.
      packet[0, 6], packet[6, 6] = packet[6, 6], packet[0, 6]
      send_data packet
    end
  end

  class ConnectionWrapper
    include Connection
    
    def initialize(socket)
      @socket = socket
    end
    
    def send_data(data)
      @socket.send data, 0
    end
  end
  
  def run
    connection = ConnectionWrapper.new @socket
    loop do
      packet = @socket.recv 65536
      connection.receive_data packet
    end
  end
  
  def initialize(eth_device, ether_type)
    @socket = Ethernet::RawSocket.socket eth_device, ether_type
  end
end  # module Ethernet::PingServer
  
# Ping utility 
class PingClient
  def initialize(eth_device, ether_type, destination_mac)
    @socket = Ethernet::RawSocket.socket eth_device, ether_type
    @source_mac = [Ethernet::RawSocket.mac(eth_device).unpack('H*').first].pack('H*')[0, 6]
    @dest_mac = [destination_mac].pack('H*')[0, 6]
    @ether_type = [ether_type].pack('n')    
  end
  
  attr_reader :socket
  attr_reader :source_mac
  attr_reader :dest_mac
  
  # Pings over raw Ethernet sockets.
  #
  # Returns true if the ping receives a response, false otherwise.
  def ping(data, timeout = 1)
    data = data.clone
    # Pad data to have at least 64 bytes.
    data += "\0" * (64 - data.length) if data.length < 64
 
    ping_packet = @dest_mac + @source_mac + @ether_type + data
    @socket.send ping_packet, 0

    response_packet = @source_mac + @dest_mac + @ether_type + data
    response = @socket.recv response_packet.length * 2
    
    response == response_packet
  end
end  # module Ethernet::PingClient

end  # namespace Ethernet

# end  # namespace Scratchpad
