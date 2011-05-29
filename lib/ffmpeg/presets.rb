module FFMpeg
  module Presets
    include Enumerable
    extend self

    def define(name, extension, &blk)
      @presets = {} if @presets.nil?
      @presets[name.to_sym] = {:block => blk, :extension => extension}
    end

    def exec(name)
      @presets[name.to_sym][:config].call if @presets[name.to_sym]
    end

    def set(key, value)
      @presets[key.to_sym] = value
    end
    alias_method :[]=, :set

    def get(key)
      @presets[key.to_sym]
    end
    alias_method :[], :get

    def delete(key)
      @presets.delete key.to_sym
    end

    def exists?(key)
      @presets.has_key? key.to_sym
    end

    def each(&block)
      @presets.each(&block)
    end
  end
end

