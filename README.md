Matchete
=========

Matchete provides a DSL for method overloading based on pattern matching for Ruby.

[![Build Status](https://travis-ci.org/alehander42/matchete.svg)](https://travis-ci.org/alehander42/matchete)

It's just a quick hack inspired by weissbier and the use-return-values-of-method-definitions DSL technique used in [harmonic](https://github.com/s2gatev/harmonic)

**It supports only ruby 2.1+**

Features
--------

* `on [:value, Integer]` matches an arg with the same internal structure
* `on '#method_name'` matches args responding to `method_name`
* `on AClass` matches instances of `AClass`
* `on a: 2, method:...` matches keyword args
* `on :test?` matches with user-defined predicate methods
* `on either('#count', Array)` matches if any of the tests returns true for an arg
* `on full_match('#count', '#combine')` matches if all of the tests return true for an arg
* `on exact(Integer)` matches special values, used as shortcuts in other cases:
classes, strings starting with '#', etc
* `on having('#count' => 2)` matches objects with properties with certain values
* `default` matches when no match has been found in `on` branches



Install
-----
`gem install matchete`


Usage
-----

```ruby
class Translator
  include Matchete

  on Any, :string,
  def translate(value, to)
    value.to_s
  end

  on '#-@', :negative,
  def translate(value, to)
    - value
  end

  on String, :integer,
  def translate(value, to)
    value.to_i
  end

  default def translate(value, to)
    0
  end
end

t = Translator.new
p t.translate 72, :negative # -72
p t.translate nil, :integer # 0
```

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
class Converter
  include Matchete

  on '#special_convert',
  def convert(value)
    value.special_convert
  end

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

  on :starts_with_cat?,
  def convert(value)
    [:fail, value]
  end

  on free: Integer, method:
  def convert(free:)
    [:rofl, free]
  end

  on either('#count', Array),
  def convert(value)
    value.count
  end

  on full_match('#count', '#lala'),
  def convert(value)
    value.count + value.lala
  end

  default def convert(value)
    [:z, value]
  end

  def starts_with_cat?(value)
    value.to_s.start_with?('cat')
  end
end

class Z
  def special_convert
    [:special_convert, nil]
  end
end

converter = Converter.new
p Converter.instance_methods
p converter.convert(2) #[:integer, 2]
p converter.convert(Z.new) #[:special_convert, nil]
p converter.convert([4, 4]) # 2
p converter.convert({2 => 4}) #[:dict, [[[:integer, 2], [:integer, 4]]]
p converter.convert('reserved_l') #[:reserved_symbol, 'reserved_l']
p converter.convert('zaza') #[:string, 'zaza']
p converter.convert(['deleted', [2, Array]]) #['deleted', [2, Array]]
p converter.convert(:cat_hehe) #[:fail, :cat_hehe]
p converter.convert(free: 2) #[:rofl, 2]
p converter.convert(2.2) #[:z, 2.2]

```

version
-------
0.5.0


cbb
-----
![](https://global3.memecdn.com/kawaii-danny-trejo_o_2031011.jpg)

Todo
-----
* Clean up the specs, right now they're a mess.
* Fix all kinds of edge cases


Copyright
-----

Copyright (c) 2015 Alexander Ivanov. See LICENSE for further details.
