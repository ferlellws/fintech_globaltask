# frozen_string_literal: true

module SimpleCommand
  attr_reader :result

  module ClassMethods
    def call(*args, **kwargs)
      command = new(*args, **kwargs)
      command.call
      command
    end
  end

  def self.prepended(base)
    base.extend(ClassMethods)
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def call
    raise NotImplementedError unless defined?(super)
    @result = super
  end

  def success?
    errors.empty?
  end

  def failure?
    !success?
  end

  def errors
    @errors ||= ErrorHash.new
  end

  class ErrorHash < Hash
    def add(key, value)
      self[key] ||= []
      self[key] << value
      self[key].uniq!
    end
  end
end

