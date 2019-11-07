module HCL
  class Parser
    @parsed : Nil | Array(AST::Token)

    include Iterator(AST::Token)

    getter :source

    def initialize(@source : String, offset = 0, io : IO? = nil)
      @peg_tokens = Pegmatite.tokenize(HCL::Grammar, source, offset, io)
      @peg_iter = Pegmatite::TokenIterator.new(@peg_tokens)
    end

    def parse
      @parsed ||= to_a
    end

    def string
      parse.map { |token| token.string }.join('\n')
    end

    def values
      parse.map { |token| token.value }
    end

    def next
      if peg_main = @peg_iter.peek
        @peg_iter.next
        build_token(peg_main, @peg_iter, source)
      else
        stop
      end
    end

    private def build_token(main, iter, source) : AST::Token
      kind, start, finish = main

      token =
        case kind
        when :block then build_block(main, iter, source)
        else build_value(main, iter, source)
        end

        # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      token
    end

    private def build_value(main, iter, source) : AST::ValueToken
      kind, start, finish = main

      # Build the value from the given main token and possibly further recursion.
      value =
        case kind
        when :conditional then build_conditional(main, iter, source)
        when :expression then build_expression(main, iter, source)
        when :function_call then build_call(main, iter, source)
        when :get_attr then build_get_attr(main, iter, source)
        when :identifier then AST::IdentifierToken.new(main, source[start...finish])
        when :index then build_index(main, iter, source)
        when :literal then AST::LiteralToken.new(main, source[start...finish])
        when :number then AST::NumberToken.new(main, source[start...finish])
        when :object then build_map(main, iter, source)
        when :operation then build_operation(main, iter, source)
        when :string then AST::StringToken.new(main, source[start...finish])
        when :tuple then build_list(main, iter, source)
        else raise NotImplementedError.new(kind)
        end

      # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      value
    end

    private def build_conditional(main, iter, source) : AST::ConditionalToken
      _, start, finish = main

      predicate = iter.next_as_child_of(main)
      predicate_token = build_value(predicate, iter, source).as(AST::ExpressionToken)

      true_expr = iter.next_as_child_of(main)
      true_expr_token = build_value(true_expr, iter, source).as(AST::ExpressionToken)

      false_expr = iter.next_as_child_of(main)
      false_expr_token = build_value(false_expr, iter, source).as(AST::ExpressionToken)

      AST::ConditionalToken.new(
        main,
        source[start...finish],
        predicate_token,
        true_expr_token,
        false_expr_token
      )
    end

    private def build_expression(main, iter, source) : AST::ExpressionToken
      _, start, finish = main

      exp_terms = [] of AST::Token

      # TODO: This is wrong, but not settled on what this *is* yet.
      context = HCL::ExpressionContext.new

      iter.while_next_is_child_of(main) do |child|
        exp_terms << build_token(child, iter, source)
      end

      unless exp_terms.any?
        raise "BUG: expected expression to have content"
      end

      AST::ExpressionToken.new(
        main,
        source[start...finish],
        exp_terms,
        context
      )
    end

    private def build_get_attr(main, iter, source) : AST::GetAttrToken
      _, start, finish = main

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :identifier
        raise "BUG: expected identifier, got #{kind}"
      end

      identifier_token = build_value(next_token, iter, source).as(AST::IdentifierToken)

      AST::GetAttrToken.new(
        main,
        source[start...finish],
        identifier_token
      )
    end

    private def build_index(main, iter, source) : AST::IndexToken
      _, start, finish = main

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :expression
        raise "BUG: expected expression, got #{kind}"
      end

      expr_token = build_value(next_token, iter, source).as(AST::ExpressionToken)

      AST::IndexToken.new(
        main,
        source[start...finish],
        expr_token
      )
    end

    private def build_operation(main, iter, source) : AST::OperationToken
      _, start, finish = main

      # TODO: This is wrong, but not settled on what this *is* yet.
      context = HCL::ExpressionContext.new

      next_token = iter.peek_as_child_of(main)

      unless next_token
        raise "BUG: expected 'next_token' to not be nil"
      end

      kind, _, _ = next_token

      if kind == :operator
        operator = iter.next_as_child_of(main)
        left_operand = iter.next_as_child_of(main)
        left_operand_token = build_value(left_operand, iter, source)
        right_operand_token = nil
      elsif kind == :number || kind == :literal
        left_operand = iter.next_as_child_of(main)
        left_operand_token = build_value(left_operand, iter, source)
        operator = iter.next_as_child_of(main)
        right_operand = iter.next_as_child_of(main)
        right_operand_token = build_value(right_operand, iter, source)
      else
        raise "BUG: Expected operator, number, or literal, but got #{kind}"
      end

      _, op_start, op_finish = operator

      AST::OperationToken.new(
        main,
        source[start...finish],
        source[op_start...op_finish],
        left_operand_token,
        right_operand_token
      )
    end

    private def build_list(main, iter, source) : AST::ListToken
      _, start, finish = main
      list = AST::ListToken.new(main, source[start...finish])

      # Gather children as values into the list.
      iter.while_next_is_child_of(main) do |child|
        list << build_value(child, iter, source)
      end

      list
    end

    private def extract_identifier(main, iter, source)
      kind, start, finish = main

      if kind != :identifier
        raise "Expected identifer, but got #{kind}"
      end

      source[start...finish]
    end

    private def build_map(main, iter, source) : AST::ObjectToken
      kind, start, finish = main

      if kind != :object
        raise "Expected object, but got '#{kind}'"
      end

      values = {} of String => AST::ValueToken

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :attribute
          # Gather children as pairs of key/values into the object.
          key = build_value(iter.next_as_child_of(token), iter, source).as_s
          val = build_value(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          values[key] = val
        else
          raise "'#{kind}' is not supported within objects."
        end
      end

      AST::ObjectToken.new(
        main,
        source[start...finish],
        values
      )
    end

    private def build_block(main, iter, source) : AST::BlockToken
      _, start, finish = main
      block_dict = {} of String => AST::ValueToken
      block_args = Array(AST::IdentifierToken | AST::StringToken).new
      blocks = [] of AST::BlockToken

      block_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      has_seen_seen_inner_block = false

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :attribute
          has_seen_seen_inner_block = true
          # Gather children as pairs of key/values into the array.
          key = build_value(iter.next_as_child_of(token), iter, source).as_s
          val = build_value(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          block_dict[key] = val
        elsif kind == :block
          has_seen_seen_inner_block = true
          new_block = build_block(token, iter, source)
          iter.assert_next_not_child_of(token)
          blocks << new_block
        elsif kind == :identifier || kind == :string
          if has_seen_seen_inner_block
            raise "Found '#{kind}' but expected an attribute assignment or block."
          else
            token_node = build_value(token, iter, source)

            if kind == :identifier
              block_args << token_node.as(AST::IdentifierToken)
            elsif kind == :string
              block_args << token_node.as(AST::StringToken)
            else
              raise "BUG: Should be identifier or string"
            end
          end
        else
          pp! token
          raise "'#{kind}' is not supported within blocks."
        end
      end

      AST::BlockToken.new(
        main,
        source[start...finish],
        block_id,
        block_args,
        block_dict,
        blocks
      )
    end

    private def build_call(main, iter, source) : AST::CallToken
      _, start, finish = main
      args = [] of AST::ValueToken

      function_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      next_token = iter.next_as_child_of(main)
      kind, _, _ = next_token

      if kind != :arguments
        raise "Expected arguments, but got '#{kind}'"
      end

      iter.while_next_is_child_of(next_token) do |child|
        args << build_value(child, iter, source)
      end

      AST::CallToken.new(
        main,
        source[start...finish],
        function_id,
        args
      )
    end
  end
end
