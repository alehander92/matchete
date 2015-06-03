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
    expect(a.play(2)).to eq :integer
    expect(a.play(2.2, 4)).to eq :float
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
    expect(a.play(2)).to eq :integer
    expect(a.play(2.2)).to eq :float
    expect(a.play([2])).to eq :enumerable
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
    expect(a.play([2, 2.2])).to eq [:integer, :float]
    expect(a.play([[2], Matchete])).to eq :s
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
    expect(a.play(2, 4)).to eq 2
    expect(a.play(4, 4)).to eq 4
    expect { a.play(8, 2) }.to raise_error(Matchete::NotResolvedError)
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
    expect(a.play('zewr')).to eq 'z'
    expect(a.play('yy')).to eq 'y'
  end

  it 'can use a default method when everything else fails' do
    class A
      include Matchete

      on Integer,
      def play(value)
        :integer
      end
    end

    expect { A.new.play(2.2) }.to raise_error(Matchete::NotResolvedError)

    class A
      default def play(value)
        :else
      end
    end

    expect(A.new.play(2.2)).to eq :else
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

    expect(A.new.play(2)).to eq 2
    expect { A.new.play(5) }.to raise_error(Matchete::NotResolvedError)
  end

  it 'can use a pattern based on a lambda predicate' do
    class A
      include Matchete

      on -> x { x % 2 == 0 },
      def play(value)
        value
      end
    end

    expect(A.new.play(2)).to eq 2
    expect { A.new.play(7) }.to raise_error(Matchete::NotResolvedError)
  end

  it 'can use a pattern based on responding to methods' do
    class A
      include Matchete

      on supporting(:map),
      def play(value)
        value
      end
    end

    expect(A.new.play([])).to eq []
    expect { A.new.play(4) }.to raise_error(Matchete::NotResolvedError)
  end

  it 'can match on different keyword arguments' do
    class A
      include Matchete

      on e: Integer, f: String, method:
      def play(e:, f:)
        :y
      end
    end

    expect(A.new.play(e: 0, f: "y")).to eq :y
    expect { A.new.play(e: "f", f: Class)}.to raise_error(Matchete::NotResolvedError)
  end

  it 'can match on multiple different kinds of patterns' do
    class A
      include Matchete
    end

    expect(A.new.match_guards([Integer, Float], {}, [8, 8.8], {})).to be_truthy
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
      expect(@a.match_guard(Integer, 2)).to be_truthy
      expect(@a.match_guard(Class, 4)).to be_falsey
    end

    it 'matches methods given as symbols' do
      expect(@a.match_guard(:even?, 2)).to be_truthy
      expect { @a.match_guard(:odd?, 4) }.to raise_error
    end

    it 'matches predicates given as lambdas' do
      expect(@a.match_guard(-> x { x == {} }, {})).to be_truthy
    end

    it 'matches on regex' do
      expect(@a.match_guard(/a/, 'aw')).to be_truthy
      expect(@a.match_guard(/z/, 'lol')).to be_falsey
    end

    it 'matches on nested arrays' do
      expect(@a.match_guard([Integer, [:even?]], [2, [4]])).to be_truthy
      expect(@a.match_guard([Float, [:even?]], [2.2, [7]])).to be_falsey
    end

    it 'matches on exact values' do
      expect(@a.match_guard(2, 2)).to be_truthy
      expect(@a.match_guard('d', 'f')).to be_falsey
    end
  end
end

