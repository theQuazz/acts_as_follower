class Follow < ActiveRecord::Base

  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :polymorphic => true

  def block!
    self.update_attribute(:blocked, true)
  end

  def accept!
    self.update_attribute(:accepted, 'yes')
  end

  def ignore!
    self.update_attribute(:accepted, 'ignore')
  end

  def decline!
    self.destroy
  end

end
