# copied from github.com/pwnall/ether_shell/spec/ether_shell/socket_wrapper_spec.rb, with :%s/HighSocket/SocktWrapper/g
# :%s/HighSocket/SocketWrapper/g
# :%s/EtherShell/Ethernet/g

require File.expand_path(File.dirname(__FILE__) + '/spec_helper') # edited this line

describe 'SocketWrapper' do
  let(:eth_device) { 'eth0' }
  let(:eth_type) { 0x0800 }
  let(:mac) { Ethernet::RawSocket.mac eth_device }
  let(:dest_mac) { "\x00\x11\x22\x33\x44\x55" }
  let(:bcast_mac) { "\xff" * 6 }
  
  shared_examples_for 'a real socket' do
    it 'should output a packet' do
      @socket.send_to dest_mac, "\r\n"
    end

    it 'should receive some network noise' do
      @socket.recv_from.first.should_not be_empty
    end
  end

  describe 'on eth0' do
    before { @socket = Ethernet::SocketWrapper.new eth_device, eth_type }
    after { @socket.close }

    it_should_behave_like 'a real socket'
  end
  
  describe 'from raw socket' do
    before do
      raw_socket = Ethernet::RawSocket.socket eth_device, eth_type
      @socket = Ethernet::SocketWrapper.new raw_socket, eth_type, mac
    end
    after { @socket.close }

    it_should_behave_like 'a real socket'
  end
  
  describe 'stubbed' do
    let(:socket_stub) do
      RawSocketStub.new([
        [mac, dest_mac, "\x88\xB7", 'Wrong Ethernet type'].join,
        [bcast_mac, dest_mac, [eth_type].pack('n'), 'Wrong dest MAC'].join,
        [mac, bcast_mac, [eth_type].pack('n'), 'Bcast'].join,
        [mac, dest_mac, [eth_type].pack('n'), 'Correct'].join,
      ])
    end
    let(:socket) { Ethernet::SocketWrapper.new socket_stub, eth_type, mac }
    
    shared_examples_for 'after a small send call' do
      it 'should send a single packet' do
        socket_stub.sends.length.should == 1
      end
      it 'should pad the packet' do
        socket_stub.sends.first.length.should == 60
      end
      it 'should assemble packet correctly in send' do
        gold = [dest_mac, mac, [eth_type].pack('n'), 'Send data'].join
        socket_stub.sends.first[0, gold.length].should == gold
      end
    end
    
    describe 'send_to' do
      before { socket.send_to dest_mac, 'Send data' }
      it_should_behave_like 'after a small send call'
    end
    
    describe 'recv_from' do
      it 'should filter down to the correct packet' do
        socket.recv_from.should == ['Bcast', bcast_mac]
      end
    end
    
    describe 'unconnected' do
      it 'should complain in recv' do
        lambda { socket.recv }.should raise_error(RuntimeError)
      end

      it 'should complain in send' do
        lambda { socket.send 'Send data' }.should raise_error(RuntimeError)
      end
    end
    
    describe 'connected' do
      before { socket.connect dest_mac }
      
      describe 'send' do
        before { socket.send 'Send data' }
        it_should_behave_like 'after a small send call'
      end
      
      describe 'recv' do
        it 'should filter down to the correct packet' do
          socket.recv.should == 'Correct'
        end
      end
    end
    
    it 'should delegate close' do
      socket_stub.should_receive(:close).once
      socket.close
    end
  end
end
