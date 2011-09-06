require 'em-zeromq'

class Worker
  attr_reader :received
  
  def initialize(ctx)
    @pub = ctx.connect( ZMQ::PUB, 'ipc:///tmp/metl_sub.zmqsock')
  end
  
  def on_readable(socket, messages)
    messages.each do |m|
      puts m.copy_out_string
      @pub.send_msg "test|#{m.copy_out_string}"
    end
  end
end


EM.run do
  ctx = EM::ZeroMQ::Context.new(1)
  
  worker = Worker.new(ctx)
  
  # setup push sockets
  pull = ctx.connect( ZMQ::PULL, 'ipc:///tmp/metl_push.zmqsock', worker)
end