module Trough
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:show], Trough::Document

      return unless user

      if user.role.in?(%w( developer admin editor author ))
        can :manage, Trough::Document
        can :manage, Trough::DocumentUsage
      end

      if user.role.in?(%w( editor author ))
        cannot :destroy, Trough::Document
      end
    end
  end
end
