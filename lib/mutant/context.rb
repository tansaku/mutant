module Mutant
  # An abstract context where mutations can be appied to.
  class Context
    include Veritas::Immutable

    # Return root ast for mutated node
    #
    # @param [Rubinius::AST::Node] node
    #
    # @return [Rubinis::AST::Script]
    #
    # @api private
    #
    def root(node)
      Mutant.not_implemented(self)
    end
  end
end
