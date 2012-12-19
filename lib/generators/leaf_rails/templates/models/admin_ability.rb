class AdminAbility
  include CanCan::Ability

  ## Example:
  #
  # PERMISSIONS = [
  #   'admin',
  #   ['news',     ['none',  'create', 'update', 'destroy']],
  # ]

  PERMISSIONS = [
    'admin'
  ]

  def initialize admin=nil
    role = admin.try(:role)
    return unless role

    if role.admin_permission
      can :manage, :all
      return
    end

    ## Example:
    #
    # if %w[create update destroy].include? role.news_permissions
    #   can :index, News
    #   can :create, News
    # end
    #
    # if %w[update destroy].include? role.news_permissions
    #   can :update, News
    # end
    #
    # if %w[destroy].include? role.news_permissions
    #   can :destroy, News
    # end

  end
end