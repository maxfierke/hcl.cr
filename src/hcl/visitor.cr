module HCL
  abstract class Visitor
    abstract def visit(node : T) forall T
  end
end
