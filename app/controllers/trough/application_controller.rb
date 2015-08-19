module Trough
  class ApplicationController < ::Pig::ApplicationController
    before_action :merge_abilities

    protected

    # extend the existing abilities generated by pig
    def merge_abilities
      current_ability.merge(Trough::Ability.new(current_user))
    end
  end
end
