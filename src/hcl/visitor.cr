module HCL
  abstract class Visitor
    abstract def visit(node)
  end
end
