module Mutant
  class Subject
    class Method
      # Instance method subjects
      class Instance < self

        NAME_INDEX = 0
        SYMBOL     = '#'.freeze

        # A list of methods that will warn when they are undefined
        WARN_METHODS_UNDEFINED =
          if RUBY_ENGINE.eql?('ruby')
            [:initialize, :__send__, :object_id].freeze
          else
            EMPTY_ARRAY
          end

        # Test if method is public
        #
        # @return [Boolean]
        #
        # @api private
        #
        def public?
          scope.public_method_defined?(name)
        end
        memoize :public?

        # Prepare subject for mutation insertion
        #
        # @return [self]
        #
        # @api private
        #
        def prepare
          expected_warnings =
            if WARN_METHODS_UNDEFINED.include?(name)
              ["#{__FILE__}:#{__LINE__ + 5}: warning: undefining `#{name}' may cause serious problems\n"]
            else
              EMPTY_ARRAY
            end
          WarningExpectation.new(expected_warnings).execute do
            scope.send(:undef_method, name)
          end
          self
        end

        # Mutator for memoized instance methods
        class Memoized < self
          include AST::Sexp

          # Return source
          #
          # @return [String]
          #
          # @api private
          #
          def source
            Unparser.unparse(memoizer_node(node))
          end
          memoize :source

          # Prepare subject for mutation insertion
          #
          # @return [self]
          #
          # @api private
          #
          def prepare
            scope.send(:memoized_methods).instance_variable_get(:@memory).delete(name)
            super
            self
          end

        private

          # Return mutations
          #
          # @param [#<<] emitter
          #
          # @return [undefined]
          #
          # @api private
          #
          def generate_mutations(emitter)
            emitter << neutral_mutation
            Mutator.each(node) do |mutant|
              emitter << Mutation::Evil.new(self, memoizer_node(mutant))
            end
          end

          # Return neutral mutation
          #
          # @return [Mutation::Neutral]
          #
          # @api private
          #
          def neutral_mutation
            Mutation::Neutral.new(self, memoizer_node(node))
          end

          # Return memoizer node for mutant
          #
          # @param [Parser::AST::Node] mutant
          #
          # @return [Parser::AST::Node]
          #
          # @api private
          #
          def memoizer_node(mutant)
            s(:begin, mutant, s(:send, nil, :memoize, s(:args, s(:sym, name))))
          end

        end # Memoized
      end # Instance
    end # Method
  end # Subject
end # Mutant
