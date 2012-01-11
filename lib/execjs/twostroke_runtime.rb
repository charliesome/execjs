module ExecJS
  class TwostrokeRuntime
    class Context
      Types = Twostroke::Runtime::Types
      
      def initialize(source = "")
        @vm = Twostroke::Runtime::VM.new({})
        @vm.eval source
      end

      def exec(source, options = {})
        eval "(function(){#{source}})();", options
      end

      def eval(source, options = {})
        unbox @vm.eval(source)
      end

      def call(properties, *args)
        val = nil
        e = catch :exception do
          val = @vm.eval(properties).call(nil, nil, args.map { |o| box o })
        end
        return val if val
        err = e.get("toString").call(nil, e, [])
        raise ProgramError, Types.to_string(err).string
      end

      def unbox(value)
        case value
        when  Types::Array;     value.map { |v| unbox(v) }
        when  Types::Boolean;   value.boolean
        when  Types::String;    value.string
        when  Types::Number;    value.number
        when  Types::RegExp;    value.regexp
        when  Types::Function;  lambda { |*args| value.call(nil, nil, args) }
        when  Types::Object;    hash = {}
                                value.each_enumerable_property do |k|
                                  hash[k] = unbox value.get(k)
                                end
                                hash
        else                    nil
        end
      end
      
      def box(value)
        case value
        when String;            Types::String.new value
        when Fixnum, Float;     Types::Number.new value
        when Array;             Types::Array.new value.map { |el| box el }
        when Hash;              o = Types::Object.new
                                value.each { |k,v| o.put k.to_s, box(v) }
                                o
        when nil;               Types::Null.new
        when true;              Types::Boolean.true
        when false;             Types::Boolean.false
        else                    Types::Undefined.new
        end
      end
    end

    def name
      "Twostroke"
    end

    def exec(source)
      context = Context.new
      context.exec(source)
    end

    def eval(source)
      context = Context.new
      context.eval(source)
    end

    def compile(source)
      Context.new(source)
    end

    def available?
      require "twostroke"
      true
    rescue LoadError
      false
    end
  end
end
