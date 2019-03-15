module HCL
  abstract class ValueToken < Token
    abstract def value : ValueType
  end
end
