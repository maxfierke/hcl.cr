module HCL
  Grammar = Pegmatite::DSL.define do
    # Forward-declare `array` and `block` to refer to them before defining them.
    array  = declare
    block = declare

    comment_char = range(' ', 0x10FFFF_u32)
    comment = (
      char('#') >> (~char('\n') >> comment_char).maybe.repeat >> char('\n')
    ).named(:comment, false)
    multi_comment_char = ~str("*/") >> (
      comment_char | char('\n') | char('\r') | char('\t')
    )
    multi_comment = (
      char('/') >> char('*') >>
      multi_comment_char.maybe.repeat >>
      char('*') >> char('/')
    ).named(:multi_comment, false)

    line_break = char('\r') | char('\n').named(:line_break, false)
    whitespace = (char(' ') | char('\t')).named(:whitespace, false)

    # Define what optional whitespace looks like.
    s = (multi_comment | comment | whitespace | line_break).repeat.named(:ignored, false)

    # Define what a number looks like.
    digit19 = range('1', '9')
    digit = range('0', '9')
    digits = digit.repeat(1)
    int =
      (char('-') >> digit19 >> digits) |
      (char('-') >> digit) |
      (digit19 >> digits) |
      digit
    frac = char('.') >> digits
    exp = (char('e') | char('E')) >> (char('+') | char('-')).maybe >> digits
    number = (int >> frac.maybe >> exp.maybe).named(:number)

    # Define what a string looks like.
    hex = digit | range('a', 'f') | range('A', 'F')
    string_char =
      str("\\\"") | str("\\\\") | str("\\|") |
      str("\\b") | str("\\f") | str("\\n") | str("\\r") | str("\\t") |
      (str("\\u") >> hex >> hex >> hex >> hex) |
      (~char('"') >> ~char('\\') >> range(' ', 0x10FFFF_u32))
    string = char('"') >> string_char.repeat.named(:string) >> char('"')

    identifier = (
      (range('a', 'z') | range('A', 'Z') | char('_')) >>
      (range('a', 'z') | range('A', 'Z') | digits | char('_') | char('-') | char('.')).repeat
    ).named(:identifier)

    t_null = str("null").named(:null)
    t_true = (str("true") | str("\"true\"")).named(:true)
    t_false = (str("false") | str("\"false\"")).named(:false)
    bool = t_true | t_false

    # Define what constitutes a value.
    value = t_null | bool | number | string | array

    # Define what an array is, in terms of zero or more values.
    values = value >> s >> (char(',') >> s >> value).repeat
    array.define \
      (char('[') >> s >> values.maybe >> s >> char(']')).named(:array)

    # Define what an object is, in terms of zero or more key/value pairs.
    pair = (identifier >> s >> char('=') >> s >> value).named(:assignment)
    object_item = pair | block
    object_list = object_item >> s >> (object_item >> s).repeat
    block_body = (char('{') >> s >> object_list.maybe >> s >> char('}')).named(:block_body)

    block_args = (string >> s).maybe.repeat.named(:block_args)
    block.define \
      (identifier >> s >> block_args >> block_body).named(:block)
    blocks = block >> s >> block.repeat

    # An HCL document is an array or object with optional surrounding whitespace.
    (s >> blocks >> s).then_eof
  end
end
