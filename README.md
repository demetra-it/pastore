# Pastore

Pastore is a powerful gem for Rails that simplifies the process of validating parameters and controlling access to actions in your controllers.
With Pastore, you can easily define validations for your parameters, ensuring that they meet specific requirements before being passed to your controller actions.
Additionally, Pastore allows you to easily control access to your actions, ensuring that only authorized users can access sensitive information.
With its intuitive interface and robust features, Pastore is a must-have tool for any Rails developer looking to improve the security and reliability of their application.

## Installation

Install the gem and add to the application's Gemfile by executing:

    bundle add pastore

If bundler is not being used to manage dependencies, install the gem by executing:

    gem install pastore

## Usage

Pastore gem implements 2 main features: `Guards` and `Validators`. Guards are intended to be used for action access control, while Validators are intended to be used for actions params validation.

### Guards usage

`Guards` feature allows you to define access control logic for actions in Rails controllers. To use the `Guards` you have to include `Pastore::Guards` into your Rails controller.

##### Setup

The best way to start using the `Guards` feature is to add the following code to your `ApplicationController`:

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::API
  include Pastore::Guards

  # Specify the logic for current user's role detection, which will be used to check
  # if current user is authorized to access a specific action.
  detect_role do
    current_user&.role
  end
end
```

In this way all your controllers will inherit the authorization settings from `ApplicationController`. Then in your controller you can do something like this:

```ruby
class MyController < ApplicationController
  # By default a :deny strategy is used, so with #permit_role we're going
  # to specify which roles are allowed to access this action.
  permit_role :admin, :user, :pm
  def index
    # ... action code ...
  end

  # Without a `permit_role` definition the access to this action will be denied to everyone.
  def not_allowed_action
    # ... action code ...
  end
end
```

If you want to use `Guards` only in specific controllers, just include `Pastore::Guards` and define `detect_role` in your controller:

```ruby
class CustomController < ApplicationController
  include Pastore::Guards

  detect_role do
    current_user&.role
  end

  permit_role :admin, :supervisor
  def index
    # ... action code ...
  end
end
```

#### Custom authorization logic

If checking user's role is not enough, you can use the `authorize_with` helper, which will allow you to specify a custom access logic by providing a method name (where custom logic is defined) or a block to use for access verification. As a result your block or method should return `true` if access is granted, or `false` otherwise.

```ruby
class MyController < ApplicationController
  # You can override the role detection logic inside a controller if it's necessary by
  # using the `detect_role` helper.
  detect_role do
    current_user&.selected_role
  end

  # If you want to use a custom/dynamic authorization logic, you can
  # specify your own implementation in a method.
  authorize_with :custom_authorization
  def index
    # ... action code ...
  end

  # You can also specify the authorization logic in a block.
  authorize_with { custom_authorized? }
  def show
    # ... action code ...
  end

  # Allow only users with `admin` role to access this action.
  permit_role :admin
  def update
  end

  private

  # Specify a custom authorization logic (return `true` if successful and `false` when forbidden).
  def custom_authorization
    # ... your custom authorization logic here ...
  end
end
```

#### Using `allow` strategy

By default `Pastore::Guards` will use `deny` strategy, which means that the access is denied by default, and the only way to access it is through explicit authorization.

Sometimes you might prefere a `allow` strategy instead, in order to allow access to any action within the controller by default, and manually restrict access to specified actions and roles.

For doing so you can use `use_allow_strategy!`, which changes the default strategy. In this case you should use `deny_role` to disable the access for a specific role.



```ruby
class MyController < ApplicationController
  # By default allow access to any action within the controller by any role.
  use_allow_strategy!

  # In this case we're using the :allow strategy, so if we want to exclude a specific role
  # we can do it by using #deny_role method.
  deny_role :user
  def index
    # ... action code ...
  end

  # Check access by using a custom method
  authorize_with :custom_autorization
  def restricted_access_action
    # ... action code ...
  end

  # Check access by using a block
  authorize_with { current_user&.role == 'admin' }
  def restricted_access_action2
    # ... action code ...
  end

  private

  # Specify a custom authorization logic (return `true` if successful and `false` when forbidden).
  def custom_autorization
    # ... custom authorization logic ...
  end
end
```

#### `Pastore::Guards` features

Below you can find the list of methods implemented by `Pastore::Guards`, that can be used inside
your Rails Controller.

| Method | Description |
|--------|-------------|
| `use_deny_strategy!` | Set to `deny` the default authorization strategy, which meands that by default the access to the actions will be denied |
| `use_allow_strategy!` | Set to `allow` the default authorization strategy, which automatically authorizes the access to all the actions. **!!! WARNING !!!** Be careful when using `allow` strategy, because that way any user can access any action of your controller, including guest users if not filtered before. |
| `detect_role(&block)` | Allows to specify the logic for user role detection. This block will be automatically called to get current user's role information. |
| `permit_role(*roles)` | Specifies the roles that are allowed to access the action that follows. |
| `deny_role(*roles)` | Specifies the roles that are not allowed to access the action that follows. |
| `authorize_with(Symbol|&block)` | Allowe to specify a custom authorization logic to use for action access check. Accepts a method name or a block. |

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/demetra-it/pastore>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/demetra-it/pastore/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pastore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pastore/blob/master/CODE_OF_CONDUCT.md).