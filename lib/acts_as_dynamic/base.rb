module ActsAsDynamic
  module Base
    def acts_as_dynamic
      include InstanceMethods
    end

    module InstanceMethods
      
      def do_method_test
        puts "I am working"
      end
      
    end
  end
end

