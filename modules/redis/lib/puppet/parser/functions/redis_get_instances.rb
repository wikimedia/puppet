# == Function: redis_get_instances ($my_ip, $shards)
#
# Returns the list of ports on which there should be a redis instance to
# listen to
#
module Puppet::Parser::Functions
  newfunction(:redis_get_instances, :type => :rvalue, :arity => 2) do |args|
    ip = args[0]
    shards = args[1]
    instances = []
    site = compiler.topscope.lookupvar('site')
    shards[site].each do |name, data|
      if data['host'] == ip
        instances << data['port']
      end
    end
    instances
  end
end
