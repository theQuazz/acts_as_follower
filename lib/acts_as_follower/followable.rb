module ActsAsFollower #:nodoc:
  module Followable

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_followable
        has_many :followings, :as => :followable, :dependent => :destroy, :class_name => 'Follow'
        include ActsAsFollower::Followable::InstanceMethods
        include ActsAsFollower::FollowerLib
        extend ActsAsFollower::Followable::SingletonMethods
      end
    end

    module SingletonMethods
      def unfollowed
        self.where("NOT EXISTS (SELECT 1 FROM follows WHERE followable_id = #{self.table_name}.id AND followable_type = '#{self.model_name}')")
      end
    end

    module InstanceMethods

      # Returns the number of followers a record has.
      def followers_count
        self.followings.unblocked.accepted.count
      end

      # Returns the followers by a given type
      def followers_by_type(follower_type, options={})
        follows = follower_type.constantize.
          joins(:follows).
          where('follows.blocked'         => false,
                'follows.accepted'        => 'yes',
                'follows.followable_id'   => self.id,
                'follows.followable_type' => parent_class_name(self.class),
                'follows.follower_type'   => follower_type)
        if options.has_key?(:limit)
          follows = follows.limit(options[:limit])
        end
        if options.has_key?(:includes)
          follows = follows.includes(options[:includes])
        end
        follows
      end

      def followers_by_type_count(follower_type)
        self.followings.unblocked.accepted.for_follower_type(follower_type).count
      end

      # Allows magic names on followers_by_type
      # e.g. user_followers == followers_by_type('User')
      # Allows magic names on followers_by_type_count
      # e.g. count_user_followers == followers_by_type_count('User')
      def method_missing(m, *args)
        if m.to_s[/count_(.+)_followers/]
          followers_by_type_count($1.singularize.classify)
        elsif m.to_s[/(.+)_followers/]
          followers_by_type($1.singularize.classify)
        else
          super
        end
      end

      def blocked_followers_count
        self.followings.blocked.count
      end

      # Returns the following records.
      def followers(options={})
        self.followings.accepted.unblocked.includes(:follower).all(options).collect{|f| f.follower}
      end

      def blocks(options={})
        self.followings.blocked.includes(:follower).all(options).collect{|f| f.follower}
      end

      def ignored_followers(options={})
        self.followings.ignored.includes(:follower).all(options).collect{|f| f.follower}
      end

      def pending_followers(options={})
        self.followings.pending.includes(:follower).all(options).collect{|f| f.follower}
      end

      # Returns true if the current instance is followed by the passed record
      # Returns false if the current instance is blocked by the passed record or no follow is found
      def followed_by?(follower)
        self.followings.accepted.unblocked.for_follower(follower).exists?
      end

      def block(follower)
        get_follow_for(follower) ? block_existing_follow(follower) : block_future_follow(follower)
      end

      def unblock(follower)
        get_follow_for(follower).try(:delete)
      end

      def get_follow_for(follower)
        self.followings.for_follower(follower).first
      end

      def accept_follower(follower)
        get_follow_for(follower).accept! if get_follow_for(follower)
      end

      def ignore_follower(follower)
        get_follow_for(follower).ignore! if get_follow_for(follower)
      end

      def decline_follower(follower)
        get_follow_for(follower).decline! if get_follow_for(follower)
      end

      def is_ignoring_follows_from(follower)
        self.followings.ignored.for_follower(follower).exists?
      end

      def has_pending_follow_request_from(follower)
        self.followings.pending.for_follower(follower).exists?
      end

      private

      def block_future_follow(follower)
        follows.create(:followable => self, :follower => follower, :blocked => true)
      end

      def block_existing_follow(follower)
        get_follow_for(follower).block!
      end

    end

  end
end
