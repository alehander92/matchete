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

  it 'can use a pattern based on existing predicate methods given as symbols' do
    class A
      include Matchete

      on :even?,
      def play(value)
        value
      end
      
      def even?(value)
        value.remainder(2).zero? #so gay and gay
      end
    end

    A.new.play(2).should eq 2
    -> { A.new.play(5) }.should raise_error(Matchete::NotResolvedError)
  end

  it 'can use a pattern based on a lambda predicate' do
    class A
      include Matchete

      on -> x { x % 2 == 0 },
      def play(value)
        value
      end
    end

    A.new.play(2).should eq 2
    -> { A.new.play(7) }.should raise_error(Matchete::NotResolvedError)
  end

  it 'can use a pattern based on responding to methods' do
    class A
      include Matchete

      on supporting(:map),
      def play(value)
        value
      end
    end

    A.new.play([]).should eq []
    -> { A.new.play(4) }.should raise_error(Matchete::NotResolvedError)
  end

  it 'can match on different keyword arguments' do
    class A
      include Matchete

      on e: Integer, f: String, method:
      def play(e:, f:)
        :y
      end
    end

    A.new.play(e: 0, f: "y").should eq :y
    -> { A.new.play(e: "f", f: Class)}.should raise_error(Matchete::NotResolvedError)
  end

  it 'can match on multiple different kinds of patterns' do
    class A
      include Matchete
    end

    A.new.match_guards([Integer, Float], {}, [8, 8.8], {}).should be_true
  end

  describe '#match_guard' do
    before :all do
      class A
        include Matchete

        def even?(value)
          value.remainder(2).zero?
        end
      end
      @a = A.new
    end

    it 'matches modules and classes' do
      @a.match_guard(Integer, 2).should be_true
      @a.match_guard(Class, 4).should be_false
    end

    it 'matches methods given as symbols' do
      @a.match_guard(:even?, 2).should be_true
      -> { @a.match_guard(:odd?, 4) }.should raise_error
    end

    it 'matches predicates given as lambdas' do
      @a.match_guard(-> x { x == {} }, {}).should be_true
    end

    it 'matches on regex' do
      @a.match_guard(/a/, 'aw').should be_true
      @a.match_guard(/z/, 'lol').should be_false
    end

    it 'matches on nested arrays' do
      @a.match_guard([Integer, [:even?]], [2, [4]]).should be_true
      @a.match_guard([Float, [:even?]], [2.2, [7]]).should be_false      
    end

    it 'matches on exact values' do
      @a.match_guard(2, 2).should be_true
      @a.match_guard('d', 'f').should be_false
    end
  end
end
  