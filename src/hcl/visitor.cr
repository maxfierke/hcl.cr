module HCL
  abstract class Visitor
    def visit_any(node)
      true
    end

    abstract def visit(node)

    def end_visit(node)
    end

    def end_visit_any(node)
    end
  end
end
