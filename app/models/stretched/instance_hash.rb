module Stretched
  class InstanceHash < Hash
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::IndifferentAccess
  end
end
