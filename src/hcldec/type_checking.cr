module HCLDec
  TYPE_PREFIX = "__$$hcl$$__$$typedef$$"
  TYPE_ANY    = "#{TYPE_PREFIX}_any"
  TYPE_BOOL   = "#{TYPE_PREFIX}_bool"
  TYPE_NUMBER = "#{TYPE_PREFIX}_number"
  TYPE_STRING = "#{TYPE_PREFIX}_string"
  TYPES       = [TYPE_ANY, TYPE_BOOL, TYPE_NUMBER, TYPE_STRING]
end
