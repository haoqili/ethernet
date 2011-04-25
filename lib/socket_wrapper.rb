# copied from github.com/pwnall/ether_shell/lib/ether_shell/high_socket.rb

# :nodoc: namespace
module Ethernet # changed from EtherShell

# Wraps an Ethernet socket and abstracts away the Ethernet II frame.
class SocketWrapper #changed from HihSocket
  # Creates a wrapper around a raw Ethernet socket.
  #
  # Args:
  # raw_socket_or_device:: a raw Ethernet socket or a string containing an
  # Ethernet device name
  # ether_type:: 2-byte Ethernet packet type number
  # mac_address:: 6-byte MAC address for the Ethernet socket (optional if
  # raw_socket_or_device is an Ethernet device name)
  #
  # Raises:
  # RuntimeError:: if mac isn't exactly 6-bytes long
  def initialize(raw_socket_or_device, ether_type, mac_address = nil)
    check_mac mac_address if mac_address
    
    if raw_socket_or_device.respond_to? :to_str
      @source_mac = mac_address || RawSocket.mac(raw_socket_or_device)
      @socket = RawSocket.socket raw_socket_or_device, ether_type
    else
      raise 'MAC address needed with raw socket' unless mac_address
      @source_mac = mac_address.dup
      @socket = raw_socket_or_device
    end
    
    @dest_mac = nil
    @ether_type = [ether_type].pack('n')
  end

  # Sets the destination MAC address for future calls to send.
  #
  # Args:
  # mac:: 6-byte MAC address for the Ethernet socket
  #
  # Raises:
  # RuntimeError:: if mac isn't exactly 6-bytes long
  def connect(mac_address)
    check_mac mac_address
    @dest_mac = mac_address
  end
  
  # Closes the underlying socket.
  def close
    @socket.close
  end
  
  # Sends an Ethernet II frame.
  #
  # Args:
  # data:: the data bytes to be sent
  #
  # Raises:
  # RuntimeError:: if connect wasn' previously called
  def send(data, send_flags = 0)
    raise "Not connected" unless @dest_mac
    send_to @dest_mac, data, send_flags
  end
  
  # Sends an Ethernet II frame.
  #
  # Args:
  # mac_address:: the destination MAC address
  # data:: the data bytes to be sent
  #
  # Raises:
  # RuntimeError:: if connect wasn' previously called
  def send_to(mac_address, data, send_flags = 0)
    check_mac mac_address

    padding = (data.length < 46) ? "\0" * (46 - data.length) : ''
    packet = [mac_address, @source_mac, @ether_type, data, padding].join
    @socket.send packet, send_flags
  end
  
  # Receives an Ethernet II frame.
  #
  # Args:
  # buffer_size:: optional maximum packet size argument passed to the raw
  # socket's recv method
  #
  # Returns the data and the source MAC address in the frame.
  #
  # This will discard incoming frames that don't match the MAC address that the
  # socket is connected to, or the Ethernet packet type.
  def recv(buffer_size = 8192)
    raise "Not connected" unless @dest_mac
    loop do
      data, mac_address = recv_from buffer_size
      return data if @dest_mac == mac_address
    end
  end
  
  # Receives an Ethernet II frame.
  #
  # Args:
  # buffer_size:: optional maximum packet size argument passed to the raw
  # socket's recv method
  #
  # Returns the data in the frame.
  #
  # This will discard incoming frames that don't match the MAC address that the
  # socket is connected to, or the Ethernet packet type.
  def recv_from(buffer_size = 8192)
    loop do
      packet = @socket.recv buffer_size
      next unless packet[12, 2] == @ether_type
      next unless packet[0, 6] == @source_mac
      return packet[14..-1], packet[6, 6]
    end
  end
  
  # Raises an exception if the given MAC address is invalid.
  def check_mac(mac_address)
    raise "Invalid MAC address" unless mac_address.length == 6
  end
  private :check_mac
end # class Ethernet::SocketWrapper

end # namespace Ethernet
