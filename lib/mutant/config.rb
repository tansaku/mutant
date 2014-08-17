module Mutant
  # The configuration of a mutator run
  class Config
    include Adamantium::Flat, Anima::Update, Anima.new(
      :debug,
      :expected_coverage,
      :fail_fast,
      :includes,
      :integration,
      :isolation,
      :matcher_config,
      :requires,
      :reporter,
      :processes,
      :zombie
    )

    [:fail_fast, :zombie, :debug].each do |name|
      define_method(:"#{name}?") { public_send(name) }
    end

    boolean = Morpher.sexp { s(:guard, s(:boolean)) }

    string_array = Morpher.sexp do
      s(:map, s(:primitive, String))
    end

    integration = Morpher.sexp do
      s(:block,
        s(:guard, s(:primitive, String)),
        s(:custom, [Mutant::Integration.method(:setup), :name.to_proc])
      )
    end

    load_isolation = lambda do |input|
      raise unless input.eql?('fork')
      Mutant::Isolation::Fork
    end

    isolation = Morpher.sexp do
      s(:custom, [load_isolation, ->(_isolation) { 'fork' }])
    end

    expression_array = Morpher.sexp do
      s(:block,
        s(:guard, s(:primitive, Array)),
        s(:map, s(:custom, [Mutant::Expression.method(:parse), :syntax.to_proc]))
      )
    end

    matcher_config = Morpher.sexp do
      s(:block,
        s(:guard, s(:primitive, Hash)),
        s(:hash_transform,
          s(:key_symbolize, :match_expressions, expression_array),
          s(:key_symbolize, :subject_ignores,   expression_array),
          s(:key_symbolize, :subject_selects,   expression_array)
        ),
        s(:anima_load, Matcher::Config)
      )
    end

    load_cli = lambda do |input|
      raise unless input.eql?('cli')
      Mutant::Reporter::CLI.build($stdout)
    end

    reporter = Morpher.sexp do
      s(:custom, [load_cli, ->(_reporter) { 'cli' }])
    end

    LOADER = Morpher.build do
      s(:block,
        s(:hash_transform,
          s(:key_symbolize, :debug,             boolean),
          s(:key_symbolize, :expected_coverage, s(:guard, s(:primitive, Float))),
          s(:key_symbolize, :fail_fast,         boolean),
          s(:key_symbolize, :includes,          string_array),
          s(:key_symbolize, :integration,       integration),
          s(:key_symbolize, :isolation,         isolation),
          s(:key_symbolize, :matcher_config,    matcher_config),
          s(:key_symbolize, :requires,          string_array),
          s(:key_symbolize, :reporter,          reporter),
          s(:key_symbolize, :processes,         s(:guard, s(:primitive, Fixnum))),
          s(:key_symbolize, :zombie,            boolean)
        ),
        s(:anima_load, Config)
      )
    end

    # Load configuration from hash
    #
    # @param [Hash] input
    #
    # @return [Config]
    #
    # @api private
    #
    def self.load(input)
      LOADER.call(input)
    end

  end # Config
end # Mutant
