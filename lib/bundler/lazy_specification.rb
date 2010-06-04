require "uri"
require "rubygems/spec_fetcher"

module Bundler
  class LazySpecification
    attr_reader :name, :version, :dependencies, :platform
    attr_accessor :source

    def initialize(name, version, platform, source = nil)
      @name          = name
      @version       = version
      @dependencies  = []
      @platform      = platform
      @source        = source
      @specification = nil
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{@name}-#{@version}"
      else
        "#{@name}-#{@version}-#{platform}"
      end
    end

    def satisfies?(dependency)
      @name == dependency.name && dependency.requirement.satisfied_by?(Gem::Version.new(@version))
    end

    def match_platform(p)
      platform.nil? or p == platform or
      (p != Gem::Platform::RUBY and p =~ platform) or
      (p == Gem::Platform::RUBY and platform.to_generic == Gem::Platform::RUBY)
    end

    def to_lock
      if platform == Gem::Platform::RUBY or platform.nil?
        out = "    #{name} (#{version})\n"
      else
        out = "    #{name} (#{version}-#{platform})\n"
      end

      dependencies.sort_by {|d| d.name }.each do |dep|
        next if dep.type == :development
        out << "    #{dep.to_lock}\n"
      end

      out
    end

    def __materialize__(index)
      @specification = index.search(Gem::Dependency.new(name, version)).last
      raise "Could not materialize #{full_name}" unless @specification
      @specification
    end

    def respond_to?(*args)
      super || @specification.respond_to?(*args)
    end

  private

    def method_missing(method, *args, &blk)
      if Gem::Specification.new.respond_to?(method)
        raise "LazySpecification has not been materialized yet (calling :#{method} #{args.inspect})" unless @specification
        @specification.send(method, *args, &blk)
      else
        super
      end
    end

  end
end