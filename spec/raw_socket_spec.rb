# copied from github.com/pwnall/ether_shell/spec/ether_shell/raw_socket_spec.rb
#:%s/EtherShell/Ethernet/g

require File.expand_path(File.dirname(__FILE__) + '/spec_helper') #I edited this original

describe 'RawSocket' do
  let(:eth_device) { 'eth0' }
  let(:mac) { Ethernet::RawSocket.mac eth_device }
  
  describe 'mac' do
    let(:golden_mac) do
      hex_mac = `ifconfig #{eth_device}`[/HWaddr .*$/][7..-1]
      [hex_mac.gsub(':', '').strip].pack('H*')
    end
    
    it 'should have 6 bytes' do
      mac.length.should == 6
    end
    
    it 'should match ifconfig output' do
      mac.should == golden_mac
    end
  end
  
  describe 'socket' do
    let(:eth_type) { 0x88B7 }
    
    before { @socket = Ethernet::RawSocket.socket eth_device }
    after { @socket.close }
    
    it 'should be able to receive data' do
      @socket.should respond_to(:recv)
    end
    
    it 'should output a packet' do
      packet = [mac, mac, [eth_type].pack('n'), "\r\n" * 32].join
      @socket.send packet, 0
    end

    it 'should receive some network noise' do
      @socket.recv(8192).should_not be_empty
    end
  end
end
