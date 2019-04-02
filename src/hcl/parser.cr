module HCL
  class Parser
    @parsed : Nil | Array(AST::Token)

    include Iterator(AST::Token)

    getter :source

    def initialize(@source : String)
      @peg_tokens = Pegmatite.tokenize(HCL::Grammar, source)
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
        when :null then AST::NullToken.new(main)
        when :true then AST::TrueToken.new(main)
        when :false then AST::FalseToken.new(main)
        when :value_ref then build_value_ref(main, iter, source)
        when :identifier then AST::IdentifierToken.new(main, source[start...finish])
        when :string then AST::StringToken.new(main, source[start...finish])
        when :number then AST::NumberToken.new(main, source[start...finish])
        when :call then build_call(main, iter, source)
        when :list then build_list(main, iter, source)
        when :map then build_map(main, iter, source)
        else raise NotImplementedError.new(kind)
        end

      # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      value
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

    private def build_map(main, iter, source) : AST::MapToken
      kind, start, finish = main

      if kind != :map
        raise "Expected map, but got #{kind}"
      end

      values = {} of String => AST::ValueToken

      iter.while_next_is_child_of(main) do |token|
        kind, _, _ = token

        if kind == :assignment
          # Gather children as pairs of key/values into the map.
          key = build_value(iter.next_as_child_of(token), iter, source).as_s
          val = build_value(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          values[key] = val
        else
          raise "#{kind} is not a supported token within maps."
        end
      end

      AST::MapToken.new(
        main,
        source[start...finish],
        values
      )
    end

    private def build_block(main, iter, source) : AST::BlockToken
      _, start, finish = main
      block_dict = {} of String => AST::ValueToken
      blocks = [] of AST::BlockToken

      block_id = extract_identifier(iter.next_as_child_of(main), iter, source)
      block_args = build_list(iter.next_as_child_of(main), iter, source).children.map do |arg|
        raise "Expected 'string', but got '#{arg.kind}'" unless arg.is_a?(AST::StringToken)
        arg.as(AST::StringToken)
      end
      block_body = iter.next_as_child_of(main)

      if block_body[0] != :block_body
        raise "Expected 'block_body', but got #{block_body[0]}"
      end

      iter.while_next_is_child_of(block_body) do |token|
        kind, _, _ = token

        if kind == :assignment
          # Gather children as pairs of key/values into the array.
          key = build_value(iter.next_as_child_of(token), iter, source).as_s
          val = build_value(iter.next_as_child_of(token), iter, source)
          iter.assert_next_not_child_of(token)
          block_dict[key] = val
        elsif kind == :block
          new_block = build_block(token, iter, source)
          iter.assert_next_not_child_of(token)
          blocks << new_block
        else
          raise "#{kind} is not a supported token within blocks."
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

    private def build_value_ref(main, iter, source) : AST::ValueRefToken
      _, start, finish = main

      iter.while_next_is_child_of(main) do |child|
        pp! child
      end

      AST::ValueRefToken.new(main, source[start...finish])
    end

    private def build_call(main, iter, source) : AST::CallToken
      _, start, finish = main
      args = [] of AST::ValueToken

      function_id = extract_identifier(iter.next_as_child_of(main), iter, source)

      iter.while_next_is_child_of(main) do |child|
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
