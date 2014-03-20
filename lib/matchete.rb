require 'set'

module Matchete
  class NotResolvedError < StandardError
  end

  def self.included(klass)
    klass.extend ClassMethods
    klass.instance_variable_set "@functions", {}
    klass.instance_variable_set "@default_functions", {}
  end

  Any = -> (x) { true }
  None = -> (x) { false }

  module ClassMethods
    def on(*guards, function)
      @functions[function] ||= []
      @functions[function] << [guards, instance_method(function)]
      convert_to_matcher function
    end

    def default(method_name)
      @default_functions[method_name] = instance_method(method_name)
      convert_to_matcher method_name
    end

    def duck(*method_names)
      -> object do
        method_names.all? do |method_name|
          object.respond_to? method_name
        end
      end
    end

    def convert_to_matcher(function)
      define_method(function) do |*args|
        guards = self.class.instance_variable_get('@functions')[function].find do |guards, _|
          self.class.match_guards guards, args
        end
        
        handler = if guards.nil?
          default_method = self.class.instance_variable_get('@default_functions')[function]
          if default_method
            default_method
          else
            raise NotResolvedError.new("not resolved #{function} with #{args}")
          end
        else
          guards[1]
        end

        handler.bind(self).call *args
      end
    end

    def match_guards(guards, args)
      guards.zip(args).all? do |guard, arg|
        match_guard guard, arg
      end
    end

    def match_guard(guard, arg)
      case guard
        when Module
          arg.is_a? guard
        when Symbol
          send guard, arg
        when Proc
          guard.call arg
        when String
          guard == arg
        when Regexp
          arg.is_a? String and guard.match arg
        when Array
          arg.is_a?(Array) and
          guard.zip(arg).all? { |child_guard, child| match_guard child_guard, child }
        else
          guard == arg
      end
    end
  end
end

