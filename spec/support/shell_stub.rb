class ShellStub
  include Ethernet::ShellDsl #changed from EtherShell::ShellDsl
  
  def initialize()
    @console = nil
  end
  attr_reader :console
  
  def print(output)
    raise "Console output not allowed" unless @console
    @console << output
  end
  
  def allow_console
    @console ||= ''
  end
end
