module Trough
  class Ability
    include CanCan::Ability

    def initialize(user)

      can [:show], Document
      if user.role_is?(:developer) || user.role_is?(:admin)
        can :manage, :all
      end
    end
  end
end
