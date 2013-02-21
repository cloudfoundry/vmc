require "vmc/cli"

module VMC
  module User
    class Base < CLI
      def precondition
        check_logged_in
      end

      private

      def validate_password!(password)
        validate_password_verified!(password)
        validate_password_strength!(password)
      end

      def validate_password_verified!(password)
        fail "Passwords do not match." unless force? || password == input[:verify]
      end

      def validate_password_strength!(password)
        strength = client.respond_to?(:password_score) ? client.password_score(password) : :good
        msg = "Your password strength is: #{strength}"
        fail msg if strength == :weak
        line msg
      end
    end
  end
end
