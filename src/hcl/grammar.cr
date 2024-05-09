module HCL
  # :nodoc:
  Grammar = Pegmatite::DSL.define do
    # Forward-declare `body`, `expression`, and `expr_term` to refer to them before defining them.
    body = declare
    expression = declare
    expr_term = declare
    template = declare

    newline = (char('\r').maybe >> char('\n')).named(:newline, false)

    comment_char = range(' ', 0x10FFFF_u32)
    comment = (
      char('#') >> (~newline >> comment_char).repeat
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

    # TODO: support the spec fully: https://github.com/hashicorp/hcl/blob/hcl2/hclsyntax/spec.md#identifiers
    identifier = (
      (range('a', 'z') | range('A', 'Z') | char('_')) >>
      (range('a', 'z') | range('A', 'Z') | digits | char('_') | char('-')).repeat
    ).named(:identifier)

    _logic_operator = str("&&") | str("||") | char('!')
    _arithetic_operator = char('+') | char('-') | char('*') | char('/') | char('%')
    _compare_operator = str("==") | str("!=") | str("<=") | str(">=") |
                        char('<') | char('>')
    _binary_operator = (_compare_operator | _arithetic_operator | _logic_operator).named(:operator)
    _binary_op = expr_term >> s >> _binary_operator >> s >> expr_term
    _unary_op = (char('-') | char('!')).named(:operator) >> expr_term
    operation = (_unary_op | _binary_op).named(:operation)

    get_attr = (char('.') >> identifier).named(:get_attr)
    index = (char('[') >> snl >> expression >> snl >> char(']')).named(:index)
    splat = (
      ((char('.') >> char('*')).named(:splat) >> get_attr.repeat) |
      ((char('[') >> char('*') >> char(']')).named(:splat) >> (get_attr | index).repeat)
    )

    arguments = (
      expression >> (char(',') >> s >> expression).repeat >>
      (char(',') | str("...").named(:varadic)).maybe
    ).named(:arguments)
    function_call = (
      identifier >> char('(') >> arguments.maybe >> char(')')
    ).named(:function_call)

    variable_expr = identifier

    _tpl_literal_char =
      str("$${") |
        str("%%{") |
        (~str("${") >> ~(s >> str("${~")) >> ~str("%{") >> ~(s >> str("%{~")) >> string_char)
    _tpl_interp_begin = ~str("$${") >> ((s >> str("${~")) | str("${"))
    _tpl_interp_end = ((str("~}") >> s) | char('}'))
    _tpl_directive_begin = ~str("%%{") >> ((s >> str("%{~")) | str("%{"))
    _tpl_directive_end = _tpl_interp_end

    template_literal = _tpl_literal_char.repeat(1).named(:literal)

    template_interpolation = (
      _tpl_interp_begin >>
      s >> expression >> s >>
      _tpl_interp_end
    ).named(:template_interpolation)

    template_if = (
      _tpl_directive_begin >> s >> str("if") >> s >> expression >> s >> _tpl_directive_end >> snl >>
      template.named(:template) >> snl >>
      (
        _tpl_directive_begin >> s >> str("else") >> s >> _tpl_directive_end >> snl >>
        template.named(:template) >> snl
      ).maybe >>
      _tpl_directive_begin >> s >> str("endif") >> s >> _tpl_directive_end
    ).named(:template_if)

    template_for = (
      _tpl_directive_begin >> s >> str("for") >> s >>
      identifier >> (char(',') >> s >> identifier).maybe >> s >>
      str("in") >> s >> expression >> s >> _tpl_directive_end >>
      template.named(:template) >>
      _tpl_directive_begin >> s >> str("endfor") >> s >> _tpl_directive_end
    ).named(:template_for)

    template_directive = template_if | template_for
    template.define (
      template_directive |
      template_interpolation |
      template_literal
    ).repeat(1)

    _heredoc_template = (
      (str("<<-") | str("<<")) >> identifier.dynamic_push(:heredoc) >> s >> newline >>
      (s >> ~dynamic_match(:heredoc) >> template >> newline.named(:literal)).repeat.named(:template) >>
      s >> identifier.dynamic_pop(:heredoc)
    ).named(:heredoc)
    _quoted_template = (char('"') >> template >> char('"')).named(:template) | string_lit
    template_expr = _quoted_template | _heredoc_template

    # TODO: Spec says expression should work w/ identifier too, but Pegmatite is
    # getting a stack overflow w/ this:
    # (identifier | expression)
    _object_elem = (
      identifier >> s >> (char('=') | char(':')) >> s >> expression
    ).named(:attribute)
    _object = (
      char('{') >> snl >> (
        _object_elem >>
        (char(',') >> snl >> _object_elem >> snl).repeat >>
        char(',').maybe
      ).maybe >> snl >> char('}')
    ).named(:object)
    _tuple = (
      char('[') >> snl >> (
        expression >>
        (char(',') >> snl >> expression >> snl).repeat >>
        char(',').maybe
      ).maybe >> snl >> char(']')
    ).named(:tuple)
    collection_value = _tuple | _object

    literal_value = (
      numeric_lit |
      (str("true") | str("false") | str("null")).named(:literal)
    )

    _for_cond = (str("if") >> s >> expression)
    _for_intro =
      str("for") >> s >> identifier >> (char(',') >> s >> identifier).maybe >> s >>
        str("in") >> s >> expression >> s >> char(':')
    _for_tuple_expr =
      char('[') >> s >>
        _for_intro >> s >>
        expression >> s >>
        _for_cond.maybe >> s >>
        char(']')
    _for_object_expr =
      char('{') >> s >>
        _for_intro >> s >>
        expression >> s >> str("=>") >> s >> expression >> s >>
        str("...").maybe >> s >>
        _for_cond.maybe >> s >>
        char('}')
    for_expr = (_for_tuple_expr | _for_object_expr).named(:for_expr)

    # ExprTerm that may have properties
    _nested_expr_term = (char('(') >> snl >> expression >> snl >> char(')'))
    _prop_expr_term =
      _nested_expr_term |
        literal_value |
        _object |
        function_call |
        variable_expr

    _index_expr_term =
      _nested_expr_term |
        collection_value |
        function_call |
        variable_expr

    _access_expr_term =
      _index_expr_term | _prop_expr_term

    _traversal_expr_term =
      _access_expr_term >> (splat | index | get_attr) >> (splat | index | get_attr).repeat

    _conditional_expr_term =
      _nested_expr_term |
        (
          operation |
            _traversal_expr_term |
            template_expr |
            literal_value |
            collection_value |
            function_call |
            variable_expr
        ).named(:expression)

    expr_term.define \
      _nested_expr_term |
      _traversal_expr_term |
      template_expr |
      for_expr |
      literal_value |
      collection_value |
      function_call |
      variable_expr

    conditional = (
      _conditional_expr_term >> snl >>
      char('?') >> snl >> _conditional_expr_term >> snl >>
      char(':') >> snl >> _conditional_expr_term
    ).named(:conditional)

    expression.define \
      (conditional | operation | expr_term).named(:expression)

    one_line_block = (
      identifier >> s >>
      ((string_lit | identifier) >> s).repeat >>
      char('{') >> s >>
      (identifier >> s >> char('=') >> s >> expression >> s).named(:attribute).maybe >>
      char('}') >> s >> newline
    ).named(:block)
    block = (
      identifier >> s >>
      ((string_lit | identifier) >> s).repeat >>
      char('{') >> s >> newline >> body >> char('}') >> s >> newline
    ).named(:block)
    attribute = (
      identifier >> s >> char('=') >> s >> expression >> s >> newline
    ).named(:attribute)
    body.define \
      (snl >> (attribute | block | one_line_block).maybe >> snl).repeat

    config_file = body.then_eof
  end
end
