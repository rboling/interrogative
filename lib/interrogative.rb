require 'interrogative/question'

# A mixin for curious classes.
module Interrogative

  # Methods applicable on both the class and instance levels.
  module BaseMethods
    # Give instructions for dealing with new questions.
    #
    # @param [Proc] postprocessor a block to run after adding a question;
    #                             the question is given as the argument.
    def when_questioned(&postprocessor)
      (@_question_postprocessors||=[]) << postprocessor unless postprocessor.nil?
    end

    # Run the defined postprocessors on the given question.
    #
    # Useful when you need to postprocess questions at a higher level.
    #
    # @param [Question] question the `Question`.
    # @return [Question] the `Question`.
    def postprocess_question(question)
      unless @_question_postprocessors.nil?
        @_question_postprocessors.each do |postprocessor|
          postprocessor.call(question)
        end
      end
      question
    end

    # Give a new question.
    #
    # @param [Symbol, String] name the name (think \<input name=...>) of
    #   the question.
    # @param [String] label the text of the question (think \<label>).
    # @param [Hash] attrs additional attributes for the question.
    # @option attrs [Boolean] :long whether the question has a long answer
    #   (think \<textarea> vs \<input>).
    # @option attrs [Boolean] :multiple whether the question could have
    #   multiple answers.
    # @param [Proc] instance_block a block returning option values.
    # @return [Question] the new `Question`.
    # @see Question#options
    def question(name, text, attrs={}, &instance_block)
      q = Question.new(name, text, self, attrs, &instance_block)
      (@_questions||=[]) << q
      
      postprocess_question(q)
      return q
    end
  end

  # Methods tailored to the class level.
  #
  # These handle inheritance of questions.
  module ClassMethods
    include BaseMethods

    # Get the array of all noted questions for this class and its superclasses.
    #
    # @return [Array<Question>] array of all noted questions.
    def questions
      qs = []
      qs |= superclass.questions if superclass.respond_to? :questions
      qs |= (@_questions||=[])
      qs
    end
  end

  # Methods tailored to the instance level.
  #
  # These handle getting questions from the class level.
  module InstanceMethods
    include BaseMethods

    # Get the array of all noted questions for this instance and its class
    # (and all of its superclasses), bound to this instance.
    #
    # All questions will be bound to the instance on which `questions`
    # is called, so their `instance_block`s, if provided, will be evaluated
    # in its context.
    #
    # @return [Array<Question>]
    # @see ClassMethods#questions
    # @see Question#options
    def questions
      qs = []
      qs |= self.class.questions if self.class.respond_to? :questions
      qs |= (@_questions||=[])
      qs.map{|q| q.for_instance(self) }
    end
  end

  # Gives the class `base` Interrogative's class-level methods
  # and gives instances of `base` Interrogative's instance-level methods.
  #
  # Called when `Interrogative` is included.
  #
  # @param [Class] base the class in which `Interrogative` has been included.
  def self.included(base)
    base.extend(Interrogative::ClassMethods)
    base.class_eval do
      include Interrogative::InstanceMethods
    end
  end
end
