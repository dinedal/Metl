require 'beanstalk-client'
require 'em-zeromq'
require 'json'

Thread.abort_on_exception = true

class WorkerSubHandler
  attr_reader :received
  
  def initialize(client_ctx)
    
  end
  
  def on_readable(socket, messages)
    messages.each do |m|
      puts m.copy_out_string
    end
  end
end

if fork.nil?
  exec("beanstalkd")
else
  sleep(1)
  EM.run do
    beanstalk = Beanstalk::Pool.new(['127.0.0.1:11300'])
    beanstalk.put("{'test':'value'}")

    worker_ctx = EM::ZeroMQ::Context.new(1)
    client_ctx = EM::ZeroMQ::Context.new(1)
    
    worker_sub_handler = WorkerSubHandler.new client_ctx

    # setup push sockets
    worker_sub = worker_ctx.bind( ZMQ::SUB, 'ipc:///tmp/metl_sub.zmqsock', worker_sub_handler)
    worker_sub.subscribe 'test'
    worker_push = worker_ctx.bind( ZMQ::PUSH, 'ipc:///tmp/metl_push.zmqsock')

    client_pub = client_ctx.bind( ZMQ::PUB, 'tcp://127.0.0.1:65431')
    client_pull = client_ctx.bind( ZMQ::PULL, 'tcp://127.0.0.1:65432')

    EM::PeriodicTimer.new(0.1) do
      job = beanstalk.reserve
      worker_push.send_msg job.body
      job.delete
    end
  end
end





