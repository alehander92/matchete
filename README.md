Matchete
=========

Matchete provides a DSL for method overloading based on pattern matching for Ruby.

It's just a quick hack inspired by weissbier and the use-return-values-of-method-definitions DSL technique used in [harmonic](https://github.com/s2gatev/harmonic)

**It supports only ruby 2.1+**

Install
-----
`gem install matchete`


Usage
-----

```ruby
require 'matchete'

class FactorialStrikesAgain
  include Matchete

  on 1,
  def factorial(value)
    1
  end

  on -> x { x > 1 },
  def factorial(value)
    value * factorial(value - 1)
  end
end

FactorialStrikesAgain.new.factorial(4) #24
FactorialStrikesAgain.new.factorial(-2) #Matchete::NotResolvedError No matching factorial method for args [-2]
```

```ruby
require 'matchete'

class Converter
  include Matchete

  on Integer,
  def convert(value)
    [:integer, value]
  end
  
  on Hash,
  def convert(values)
    [:dict, values.map { |k, v| [convert(k), convert(v)] }]
  end
  
  on /reserved_/,
  def convert(value)
    [:reserved_symbol, value]
  end
  
  on String,
  def convert(value)
    [:string, value]
  end
  
  on ['deleted', [Integer, Any]],
  def convert(value)
    ['deleted', value[1]]
  end
  
  on :not_implemented?,
  def convert(value)
    [:fail, value]
  end
  
  on free: Integer, method:
  def convert(free:)
    [:rofl, free]
  end

  default def convert(value)
    [:z, value]
  end
  
  def not_implemented?(value)
    value.is_a? Symbol
  end
end

converter = Converter.new
p converter.convert(2) #[:integer, 2]
p converter.convert({2 => 4}) #[:dict, [[[:integer, 2], [:integer, 4]]]
p converter.convert('reserved_l') #[;reserved_symbol, 'l']
p converter.convert('zaza') #[:string, 'zaza']
p converter.convert(['deleted', [2, Array]]) #['deleted', [2, Array]]
p converter.convert(:f) #[:fail, :f]
p converter.convert(free: 2) #[:rofl, 2]
p converter.convert(2.2) #[:z, 2.2]
```
cbb
-----
![](https://global3.memecdn.com/kawaii-danny-trejo_o_2031011.jpg)

Todo
-----
* Clean up the specs, right now they're a mess.
* Fix all kinds of edge cases


Copyright
-----

Copyright (c) 2014 Alexander Ivanov. See LICENSE for further details.
