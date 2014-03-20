$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'matchete'

describe Matchete do
  it 'can be used to overload a method in a class' do
    class A
      include Matchete

      on Integer,
      def play(value)
        :integer
      end

      on Float, Any,
      def play(value, object)
        :float
      end
    end

    a = A.new
    a.play(2).should eq :integer
    a.play(2.2, 4).should eq :float
  end

  it 'can use a pattern based on classes and modules' do
    class A
      include Matchete

      on Integer,
      def play(value)
        :integer
      end

      on Float,
      def play(value)
        :float
      end

      on Enumerable,
      def play(value)
        :enumerable
      end
    end

    a = A.new
    a.play(2).should eq :integer
    a.play(2.2).should eq :float
    a.play([2]).should eq :enumerable
  end

  it 'can use a pattern based on nested arrays with classes/modules' do
    class A
      include Matchete

      on [Integer, Float],
      def play(values)
        [:integer, :float]
      end

      on [[Integer], Any],
      def play(values)
        :s
      end
    end

    a = A.new
    a.play([2, 2.2]).should eq [:integer, :float]
    a.play([[2], Matchete]).should eq :s
  end

  it 'can use a pattern based on exact values' do
    class A
      include Matchete

      on 2, Integer,
      def play(value, obj)
        2
      end

      on 4, Integer,
      def play(value, obj)
        4
      end
    end

    a = A.new
    a.play(2, 4).should eq 2
    a.play(4, 4).should eq 4
    -> { a.play(8, 2) }.should raise_error(Matchete::NotResolvedError)
  end

  it 'can use a pattern based on regexes' do
    class A
      include Matchete

      on /z/,
      def play(value)
        'z'
      end

      on /y/,
      def play(value)
        'y'
      end
    end

    a = A.new
    a.play('zewr').should eq 'z'
    a.play('yy').should eq 'y'
  end

  it 'can use a default method when everything else fails' do
    class A
      include Matchete

      on Integer,
      def play(value)
        :integer
      end
    end

    -> { A.new.play(2.2) }.should raise_error(Matchete::NotResolvedError)
    
    class A
      default def play(value)
        :else
      end
    end

    A.new.play(2.2).should eq :else    
  end
end