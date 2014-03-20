require 'set'

module Matchete
  class NotResolvedError < StandardError
  end

  def self.included(klass)
    klass.extend ClassMethods
    klass.instance_variable_set "@methods", {}
    klass.instance_variable_set "@default_methods", {}
  end

  Any = -> (x) { true }
  None = -> (x) { false }

  module ClassMethods
    def on(*guards, method_name)
      @methods[method_name] ||= []
      @methods[method_name] << [guards, instance_method(method_name)]
      convert_to_matcher method_name
    end

    def default(method_name)
      @default_methods[method_name] = instance_method(method_name)
      convert_to_matcher method_name
    end

    def duck(*method_names)
      -> object do
        method_names.all? do |method_name|
          object.respond_to? method_name
        end
      end
    end

    def call_overloaded(object, method_name, with: [])
      handler = find_handler(method_name, with)
      handler.bind(object).call *with
    end

    def find_handler(method_name, args)
      guards = @methods[method_name].find do |guards, _|
        match_guards guards, args
      end

      if guards.nil?
        default_method = @default_methods[method_name]
        if default_method
          default_method
        else
          raise NotResolvedError.new("No matching #{method_name} method for args #{args}")
        end
      else
        guards[1]
      end
    end

    def convert_to_matcher(method_name)
      define_method(method_name) do |*args|
        self.class.call_overloaded(self, method_name, with: args)
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

