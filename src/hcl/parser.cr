module HCL
  class Parser
    @parsed : Nil | Array(Token)

    include Iterator(Token)

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
        build_value(peg_main, @peg_iter, source)
      else
        stop
      end
    end

    private def build_value(main, iter, source)
      kind, start, finish = main

      # Build the value from the given main token and possibly further recursion.
      value =
        case kind
        when :null then Token::Null.new(main)
        when :true then Token::True.new(main)
        when :false then Token::False.new(main)
        when :identifier then Token::Identifier.new(main, source[start...finish])
        when :string then Token::String.new(main, source[start...finish])
        when :number then Token::Number.new(main, source[start...finish])
        when :array then build_array(main, iter, source)
        when :block then build_block(main, iter, source)
        else raise NotImplementedError.new(kind)
        end

      # Assert that we have consumed all child tokens.
      iter.assert_next_not_child_of(main)

      value
    end

    private def build_array(main, iter, source)
      _, start, finish = main
      array = Token::List.new(main, source[start...finish])

      # Gather children as values into the array.
      iter.while_next_is_child_of(main) do |child|
        array << build_value(child, iter, source)
      end

      array
    end

    private def build_identifier(main, iter, source)
      kind, start, finish = main

      if kind != :identifier
        raise "Expected :identifer, but got #{kind}"
      end

      source[start...finish]
    end

    private def build_block(main, iter, source)
      _, start, finish = main
      block_dict = {} of String => Token
      blocks = [] of Token::Block

      block_id = build_identifier(iter.next_as_child_of(main), iter, source)
      block_args = build_array(iter.next_as_child_of(main), iter, source).children.map do |arg|
        raise "BUG: Expected 'string', but got Array. Shouldn't be possible." if arg.is_a?(Array(Token))
        raise "Expected 'string', but got #{arg.kind}" unless arg.is_a?(Token::String)
        arg.as(Token::String)
      end
      block_body = iter.next_as_child_of(main)

      # TODO: validate block-body token type

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

      Token::Block.new(
        main,
        source[start...finish],
        block_id,
        block_args,
        block_dict,
        blocks
      )
    end
  end
end
