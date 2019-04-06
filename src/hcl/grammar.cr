module HCL
  Grammar = Pegmatite::DSL.define do
    # Forward-declare `body`, `expression`, and `expr_term` to refer to them before defining them.
    body = declare
    expression = declare
    expr_term = declare

    newline = (char('\r').maybe >> char('\n')).named(:newline, false)

    comment_char = range(' ', 0x10FFFF_u32)
    comment = (
      char('#') >> (~newline >> comment_char).repeat >> newline
    ).named(:comment, false)
    multi_comment_char = ~str("*/") >> (comment_char | newline)
    multi_comment = (
      str("/*") >> multi_comment_char.repeat >> str("*/")
    ).named(:multi_comment, false)

    whitespace = char(' ').named(:whitespace, false)
    s = (multi_comment | comment | whitespace).repeat.named(:ignored, false)
    snl = (s >> newline.maybe >> s).repeat.named(:ignored_or_newline, false)

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
    numeric = int >> frac.maybe >> exp.maybe
    numeric_lit = numeric.named(:number)

    hex = digit | range('a', 'f') | range('A', 'F')
    string_char =
      str("\\\"") | str("\\\\") |
      str("\\n") | str("\\r") | str("\\t") |
      (str("\\u") >> hex >> hex >> hex >> hex) |
      (str("\\U") >> hex >> hex >> hex >> hex >> hex >> hex >> hex >> hex) |
      (~char('"') >> ~char('\\') >> range(' ', 0x10FFFF_u32))
    string_lit = char('"') >> string_char.repeat.named(:string) >> char('"')

    identifier = (
      (range('a', 'z') | range('A', 'Z') | char('_')) >>
      (range('a', 'z') | range('A', 'Z') | digits | char('_') | char('-')).repeat
    ).named(:identifier)

    conditional = (
      expression >> s >>
      char('?') >> s >> expression >> s >>
      char(':') >> s >> expression
    ).named(:conditional)

    _logic_operator = str("&&") | str("||") | char('!')
    _arithetic_operator = char('+') | char('-') | char('*') | char('/') | char('%')
    _compare_operator = str("==") | str("!=") | char('<') |
      char('>') | str("<=") | str(">=")
    _binary_operator = _compare_operator | _arithetic_operator | _logic_operator
    _binary_op = expr_term >> s >> _binary_operator >> s >> expr_term
    _unary_op = (char('=') | char('!')) >> expr_term
    operation = (_unary_op | _binary_op).named(:operation)

    get_attr = (char('.') >> identifier).named(:get_attr)
    index = (char('[') >> expression >> char(']')).named(:index)
    splat = (
      (char('.') >> char('*') >> get_attr.repeat) |
      (char('[') >> char('*') >> char(']') >> (get_attr | index).repeat)
    ).named(:splat)

    arguments = (
      expression >> (char(',') >> s >> expression).repeat >>
      (char(',') | str("...")).maybe
    ).named(:arguments)
    function_call = (
      identifier >> char('(') >> arguments.maybe >> char(')')
    ).named(:function_call)

    variable_expr = identifier

    _heredoc_template = (
      (str("<<") | str("<<-")) >> identifier >> newline >>
      (string_char.repeat >> newline).repeat >>
      identifier >> newline
    )
    _quoted_template = string_lit
    template_expr = _quoted_template | _heredoc_template

    _object_elem = (identifier | expression) >> s >> char('=') >> s >> expression
    _object = (
      char('{') >> snl >> (
        (
          _object_elem >>
          (char(',') >> snl >> _object_elem >> snl).repeat >>
          char(',').maybe
        ).maybe
      ) >> snl >> char('}')
    ).named(:object)
    _tuple = (
      char('[') >> snl >> (
        (
          expression >>
          (char(',') >> snl >> expression >> snl).repeat >>
          char(',').maybe
        ).maybe
      ) >> snl >> char(']')
    ).named(:tuple)
    collection_value = _tuple | _object

    literal_value = (
      numeric_lit |
      str("true") |
      str("false") |
      str("null")
    ).named(:literal)

    expr_term.define (
      literal_value |
      collection_value |
      template_expr |
      variable_expr |
      function_call |
      # for_expr |
      (expr_term >> index) |
      (expr_term >> get_attr) |
      (expr_term >> splat) |
      (char('(') >> s >> expression >> s >> char(')'))
    )

    expression.define \
      (expr_term | operation | conditional).named(:expression)

    one_line_block = (
      identifier >> s >>
      ((string_lit | identifier) >> s).repeat >>
      char('{') >> s >>
      (identifier >> s >> char('=') >> s >> expression >> s).maybe >>
      char('}') >> s >> newline
    ).named(:one_line_block)
    block = (
      identifier >> s >>
      ((string_lit | identifier) >> s).repeat >>
      char('{') >> s >> newline >> body >> char('}') >> s >> newline
    ).named(:block)
    attribute = (
      identifier >> s >> char('=') >> s >> expression >> s >> newline
    ).named(:attribute)
    body.define \
      (snl >> (attribute | block | one_line_block) >> snl).repeat

    config_file = body.then_eof
  end
end
