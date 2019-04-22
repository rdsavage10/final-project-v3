class ApplicationController < ActionController::Base


    # find guest_user object associated with the current session,
    # creating one as needed
    def guest_user(with_retry = true)
      # Cache the value the first time it's gotten.
      @cached_guest_user ||= User.find(session[:guest_user_id] ||= create_guest_user.id)

    rescue ActiveRecord::RecordNotFound # if session[:guest_user_id] invalid
       session[:guest_user_id] = nil
       guest_user if with_retry
    end

    private


    def create_guest_user
      u = User.new(:email => "guest_#{Time.now.to_i}#{rand(100)}@example.com",:item_id => [1], :room_data => {})
      u.save!(:validate => false)
      session[:guest_user_id] = u.id
      u
    end

end
