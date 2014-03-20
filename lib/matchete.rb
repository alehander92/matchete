require 'set'
require_relative 'matchete/exceptions'

module Matchete
  def self.included(klass)
    klass.extend ClassMethods
    klass.instance_variable_set "@methods", {}
    klass.instance_variable_set "@default_methods", {}
  end

  Any = -> (x) { true }
  None = -> (x) { false }

  module ClassMethods
    def on(*args, **kwargs)
      if kwargs.count.zero?
        *guard_args, method_name = args
        guard_kwargs = {}
      else
        method_name = kwargs[:method]
        kwargs.delete :method
        guard_args = args
        guard_kwargs = kwargs
      end
      @methods[method_name] ||= []
      @methods[method_name] << [guard_args, guard_kwargs, instance_method(method_name)]
      convert_to_matcher method_name
    end

    def default(method_name)
      @default_methods[method_name] = instance_method(method_name)
      convert_to_matcher method_name
    end

    def supporting(*method_names)
      -> object do
        method_names.all? do |method_name|
          object.respond_to? method_name
        end
      end
    end

    def convert_to_matcher(method_name)
      define_method(method_name) do |*args, **kwargs|
        call_overloaded(method_name, args: args, kwargs: kwargs)
      end
    end
  end
  
  def call_overloaded(method_name, args: [], kwargs: {})
    handler = find_handler(method_name, args, kwargs)
    if handler.parameters.any? do |type, _|
        [:key, :keyrest, :keyreq].include? type
      end
      handler.bind(self).call *args, **kwargs
    else
      handler.bind(self).call *args
    end
    #insane workaround, because if you have
    #def z(f);end
    #and you call it like that
    #a(2, **{e: 4})
    #it raises wrong number of arguments (2 for 1)
    #clean later
  end

  def find_handler(method_name, args, kwargs)
    guards = self.class.instance_variable_get('@methods')[method_name].find do |guard_args, guard_kwargs, _|
      match_guards guard_args, guard_kwargs, args, kwargs
    end

    if guards.nil?
      default_method = self.class.instance_variable_get('@default_methods')[method_name]
      if default_method
        default_method
      else
        raise NotResolvedError.new("No matching #{method_name} method for args #{args}")
      end
    else
      guards[2]
    end
  end

  def match_guards(guard_args, guard_kwargs, args, kwargs)
    return false if guard_args.count != args.count || guard_kwargs.count != kwargs.count
    guard_args.zip(args).all? do |guard, arg|
      match_guard guard, arg
    end and
    guard_kwargs.all? do |label, guard|
      match_guard guard, kwargs[label]
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

