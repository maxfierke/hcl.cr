module HCL
  class Parser
    @filename = "???"
    @source = ""
    @source_offset = 0
    @document : AST::Document?
    @parse_trace_io : IO?

    getter :document, :source

    def self.parse!(*args, **kwargs)
      new(*args, **kwargs).parse!
    end

    def initialize(source : IO, offset = 0, io : IO? = nil)
      @filename = source.filename
      super(source.gets_to_end, offset, io: io)
    end

    def initialize(source : String, offset = 0, io : IO? = nil)
      @source = source
      @source_offset = offset
      @parse_trace_io = io
    end

    def parse!
      @document ||= begin
        peg_tokens = Pegmatite.tokenize(
          HCL::Grammar,
          @source,
          @source_offset,
          @parse_trace_io
        )
        peg_iter = Pegmatite::TokenIterator.new(peg_tokens)
        build_document(peg_iter, @source)
      rescue e : Pegmatite::Pattern::MatchError
        raise ParseException.new(e.message, source: source, match_error: e)
      end
    end

    private def assert_token_kind!(token : Pegmatite::Token, expected_kind)
      kind, _, _ = token
      assert_token_kind!(kind, expected_kind)
    end

    private def assert_token_kind!(kind : Symbol, expected_kind)
      raise ParseException.new(
        "Expected #{expected_kind}, but got #{kind}.",
        source: source
      ) unless kind == expected_kind
    end

    private def build_document(iter, source) : AST::Document
      attributes = {} of String => AST::Node
      blocks = [] of AST::Block

      while token = iter.peek
        kind, _, _ = token

        # Advance iterator now that we've seen the next token
        iter.next

        if kind == :attribute
          # Gather children as pairs of key/values into the array.
          key = build_node(iter.next_as_child_of(token), iter, source).to_s
          val = build_node(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          attributes[key] = val
        elsif kind == :block
          new_block = build_block(token, iter, source)
          iter.assert_next_not_child_of(token)
          blocks << new_block
        else
          raise ParseException.new(
            "Found '#{kind}' but expected an attribute assignment or block.",
            source: source,
            token: token
          )
        end
      end

      AST::Document.new(
        attributes,
        blocks,
        token: Pegmatite::Token.new(:document, 0, source.size),
        source: source,
      )
    end

    private def build_node(main, iter, source) : AST::Node
      kind, start, finish = main

      # Build the node from the given main token and possibly further recursion.
      value =
        case kind
        when :block                  then build_block(main, iter, source)
        when :conditional            then build_conditional(main, iter, source)
        when :expression             then build_expression(main, iter, source)
        when :function_call          then build_call(main, iter, source)
        when :get_attr               then build_get_attr(main, iter, source)
        when :for_expr               then build_for_expr(main, iter, source)
        when :heredoc                then build_heredoc(main, iter, source)
        when :identifier             then build_identifier(main, iter, source)
        when :index                  then build_index(main, iter, source)
        when :literal                then AST::Literal.new(token: main, source: token_source(main))
        when :number                 then AST::Number.new(token: main, source: token_source(main))
        when :object                 then build_map(main, iter, source)
        when :operation              then build_operation(main, iter, source)
        when :splat                  then AST::SplatExpr.new(token: main, source: token_source(main))
        when :string                 then build_string(main, iter, source)
        when :template               then build_template(main, iter, source)
        when :template_for           then build_template_for_expr(main, iter, source)
        when :template_if            then build_template_if(main, iter, source)
        when :template_interpolation then build_template_interpolation(main, iter, source)
        when :tuple                  then build_list(main, iter, source)
        else                              raise NotImplementedError.new(kind)
        end

      # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      value
    end

    private def build_conditional(main, iter, source) : AST::CondExpr
      predicate = iter.next_as_child_of(main)
      predicate_node = build_expression(predicate, iter, source)

      true_expr = iter.next_as_child_of(main)
      true_expr_node = build_expression(true_expr, iter, source)

      false_expr = iter.next_as_child_of(main)
      false_expr_node = build_expression(false_expr, iter, source)

      AST::CondExpr.new(
        predicate_node,
        true_expr_node,
        false_expr_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_expression(main, iter, source) : AST::Expression
      exp_terms = [] of AST::Node

      iter.while_next_is_child_of(main) do |child|
        exp_terms << build_node(child, iter, source)
      end

      unless exp_terms.any?
        raise "BUG: expected expression to have content"
      end

      AST::Expression.new(
        exp_terms,
        token: main,
        source: token_source(main),
      )
    end

    private def build_for_expr(main, iter, source) : AST::ForExpr
      _, start, finish = main

      for_type = source[start] == '{' ? AST::ForExpr::TYPE_MAP : AST::ForExpr::TYPE_LIST

      key_name_token = iter.next_as_child_of(main)
      assert_token_kind!(key_name_token, :identifier)
      key_name_node = build_identifier(key_name_token, iter, source)

      next_token = iter.peek_as_child_of(main)
      if next_token && next_token[0] == :identifier
        value_name_token = iter.next_as_child_of(main)
        value_name_node = build_identifier(value_name_token, iter, source)
      else
        value_name_node = key_name_node
        key_name_node = nil
      end

      coll_expr_token = iter.next_as_child_of(main)
      assert_token_kind!(coll_expr_token, :expression)
      coll_expr_node = build_expression(coll_expr_token, iter, source)

      if for_type == AST::ForExpr::TYPE_MAP
        key_expr_token = iter.next_as_child_of(main)
        assert_token_kind!(key_expr_token, :expression)
        key_expr_node = build_expression(key_expr_token, iter, source)
      else
        key_expr_node = nil
      end

      value_expr_token = iter.next_as_child_of(main)
      assert_token_kind!(value_expr_token, :expression)
      value_expr_node = build_expression(value_expr_token, iter, source)

      next_token = iter.peek_as_child_of(main)
      if next_token && next_token[0] == :expression
        cond_expr_token = iter.next_as_child_of(main)
        cond_expr_node = build_expression(cond_expr_token, iter, source)
      else
        cond_expr_node = nil
      end

      AST::ForExpr.new(
        for_type,
        coll_expr_node,
        value_name_node,
        value_expr_node,
        key_name: key_name_node,
        key_expr: key_expr_node,
        cond_expr: cond_expr_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_get_attr(main, iter, source) : AST::GetAttrExpr
      _, start, finish = main

      next_token = iter.next_as_child_of(main)
      assert_token_kind!(next_token, :identifier)

      identifier_node = build_identifier(next_token, iter, source)

      AST::GetAttrExpr.new(
        identifier_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_heredoc(main, iter, source) : AST::Heredoc
      kind, start, finish = main

      start_ident = extract_identifier(iter.next_as_child_of(main), iter, source)

      content_token = iter.next_as_child_of(main)
      assert_token_kind!(content_token, :template)
      content = build_template(content_token, iter, source)

      end_ident = extract_identifier(iter.next_as_child_of(main), iter, source)

      if start_ident != end_ident
        raise "BUG: Expected heredoc start and end identifiers to match"
      end

      AST::Heredoc.new(
        start_ident,
        content,
        token: main,
        source: token_source(main),
      )
    end

    private def build_identifier(main, iter, source) : AST::Identifier
      AST::Identifier.new(token: main, source: token_source(main))
    end

    private def build_index(main, iter, source) : AST::IndexExpr
      next_token = iter.next_as_child_of(main)
      assert_token_kind!(next_token, :expression)

      expr_node = build_expression(next_token, iter, source)

      AST::IndexExpr.new(
        expr_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_operation(main, iter, source) : AST::OpExpr
      next_token = iter.peek_as_child_of(main)

      unless next_token
        raise "BUG: expected 'next_token' to not be nil"
      end

      kind, _, _ = next_token

      if kind == :operator
        operator = iter.next_as_child_of(main)
        left_operand = iter.next_as_child_of(main)
        left_operand_node = build_node(left_operand, iter, source)
        right_operand_node = nil
      elsif kind == :identifier || kind == :number || kind == :literal || kind == :template
        left_operand = iter.next_as_child_of(main)
        left_operand_node = build_node(left_operand, iter, source)
        operator = iter.next_as_child_of(main)
        right_operand = iter.next_as_child_of(main)
        right_operand_node = build_node(right_operand, iter, source)
      else
        raise "BUG: Expected operator, number, literal, or template, but got #{kind}"
      end

      AST::OpExpr.new(
        token_source(operator),
        left_operand_node,
        right_operand_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_string(main, iter, source) : AST::Literal
      AST::Literal.new(token: main, source: token_source(main))
    end

    private def build_template(main, iter, source) : AST::Template
      template_nodes = [] of AST::Node

      iter.while_next_is_child_of(main) do |child|
        template_nodes << build_node(child, iter, source)
      end

      unless template_nodes.any?
        raise "BUG: expected template to have content"
      end

      AST::Template.new(
        template_nodes,
        token: main,
        source: token_source(main)
      )
    end

    private def build_template_for_expr(main, iter, source) : AST::TemplateForExpr
      key_name_token = iter.next_as_child_of(main)
      assert_token_kind!(key_name_token, :identifier)
      key_name_node = build_identifier(key_name_token, iter, source)

      next_token = iter.peek_as_child_of(main)
      if next_token && next_token[0] == :identifier
        value_name_token = iter.next_as_child_of(main)
        value_name_node = build_identifier(value_name_token, iter, source)
      else
        value_name_node = key_name_node
        key_name_node = nil
      end

      coll_expr_token = iter.next_as_child_of(main)
      assert_token_kind!(coll_expr_token, :expression)
      coll_expr_node = build_expression(coll_expr_token, iter, source)

      tpl_expr_token = iter.next_as_child_of(main)
      assert_token_kind!(tpl_expr_token, :template)
      tpl_expr_node = build_template(tpl_expr_token, iter, source)

      AST::TemplateForExpr.new(
        coll_expr_node,
        value_name_node,
        tpl_expr_node,
        key_name: key_name_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_template_if(main, iter, source) : AST::TemplateIf
      predicate = iter.next_as_child_of(main)
      assert_token_kind!(predicate, :expression)
      predicate_node = build_expression(predicate, iter, source)

      true_tpl = iter.next_as_child_of(main)
      assert_token_kind!(true_tpl, :template)
      true_tpl_node = build_template(true_tpl, iter, source)

      false_tpl = iter.peek_as_child_of(main)
      if false_tpl && false_tpl[0] == :template
        false_tpl_node = build_template(false_tpl, iter, source)
      else
        false_tpl_node = nil
      end

      AST::TemplateIf.new(
        predicate_node,
        true_tpl_node,
        false_tpl_node,
        token: main,
        source: token_source(main),
      )
    end

    private def build_template_interpolation(main, iter, source) : AST::TemplateInterpolation
      next_token = iter.next_as_child_of(main)
      assert_token_kind!(next_token, :expression)

      expr_node = build_expression(next_token, iter, source)

      AST::TemplateInterpolation.new(
        expr_node,
        token: main,
        source: token_source(main)
      )
    end

    private def build_list(main, iter, source) : AST::List
      list = AST::List.new(token: main, source: token_source(main))

      # Gather children as values into the list.
      iter.while_next_is_child_of(main) do |child|
        list << build_node(child, iter, source)
      end

      list
    end

    private def extract_identifier(main, iter, source)
      kind, _, _ = main
      assert_token_kind!(kind, :identifier)

      token_source(main)
    end

    private def build_map(main, iter, source) : AST::Map
      kind, _, _ = main
      assert_token_kind!(kind, :object)

      values = {} of String => AST::Node

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token
        assert_token_kind!(kind, :attribute)

        # Gather children as pairs of key/values into the object.
        key = build_node(iter.next_as_child_of(token), iter, source).to_s
        val = build_node(iter.next_as_child_of(token), iter, source)
        iter.assert_next_not_child_of(token)
        values[key] = val
      end

      AST::Map.new(
        values,
        token: main,
        source: token_source(main),
      )
    end

    private def build_block(main, iter, source) : AST::Block
      block_attributes = {} of String => AST::Node
      block_labels = [] of AST::BlockLabel
      blocks = [] of AST::Block

      block_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      has_seen_seen_inner_block = false

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :attribute
          has_seen_seen_inner_block = true
          # Gather children as pairs of key/values into the array.
          key = build_node(iter.next_as_child_of(token), iter, source).to_s
          val = build_node(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          block_attributes[key] = val
        elsif kind == :block
          has_seen_seen_inner_block = true
          new_block = build_block(token, iter, source)
          iter.assert_next_not_child_of(token)
          blocks << new_block
        elsif kind == :identifier || kind == :string
          if has_seen_seen_inner_block
            raise ParseException.new(
              "Found '#{kind}' but expected an attribute assignment or block.",
              source: source,
              token: token
            )
          else
            if kind == :identifier
              label_node = build_identifier(token, iter, source)
              block_labels << label_node
            elsif kind == :string
              label_node = build_string(token, iter, source)
              block_labels << label_node
            end
          end
        else
          raise ParseException.new(
            "'#{kind}' is not supported within blocks.",
            source: source,
            token: token
          )
        end
      end

      AST::Block.new(
        block_id,
        block_labels,
        block_attributes,
        blocks,
        token: main,
        source: token_source(main),
      )
    end

    private def build_call(main, iter, source) : AST::CallExpr
      args = [] of AST::Node

      function_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      next_token = iter.next_as_child_of(main)
      assert_token_kind!(next_token, :arguments)

      varadic = false

      iter.while_next_is_child_of(next_token) do |child|
        kind, _, _ = child

        if kind == :varadic
          varadic = true
        else
          raise ParseException.new(
            "Cannot specify additional arguments after a varadic argument (...)",
            source: source,
            token: child
          ) if varadic
          args << build_node(child, iter, source)
        end
      end

      AST::CallExpr.new(
        function_id,
        args,
        varadic,
        token: main,
        source: token_source(main),
      )
    end

    private def token_source(token)
      kind, byte_start, byte_finish = token

      start = source.byte_index_to_char_index(byte_start)
      finish = source.byte_index_to_char_index(byte_finish)

      source[start...finish]
    end
  end
end
