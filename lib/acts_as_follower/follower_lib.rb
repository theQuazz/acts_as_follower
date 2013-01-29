module ActsAsFollower
  module FollowerLib

    private

    # Retrieves the parent class name if using STI.
    def parent_class_name(klass)
      if klass.superclass != ActiveRecord::Base
        return parent_class_name klass.superclass
      end
      return klass.name
    end

  end
end
