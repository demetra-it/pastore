# `Pastore::Params`

`Pastore::Params` is the module that provides the features for params validation in Rails controllers. It allows you to define the params with their data type (`string`, `number`, `boolean`, `date` and `object`), specify which params are mandatory and cannot be blank.

**Table of Contents**

- [`Pastore::Params`](#pastoreparams)
  - [Setup](#setup)
  - [Specifying params](#specifying-params)
    - [Available param types](#available-param-types)
    - [Avaliable options](#avaliable-options)

## Setup

To start using `Pastore::Params` you just need to include `Pastore::Params` module in your controller. If you plan to use it in all your controllers, just add the following to your `ApplicationController` class:

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::API
  include Pastore::Params

  # Specify response status code to use for invalid params (default: unprocessable_entity)
  invalid_params_status :bad_request

  # Here you can customize the response to return on invalid params
  on_invalid_params do
    render json: { message: 'Invalid params' }
  end

  # ...
end
```

## Specifying params

Once you have configured `Pastore::Params` in your controller you can use the `param` method to define your params.

`param` method has the following signature:

```ruby
param PARAM_NAME, **OPTIONS
```

`PARAM_NAME` can be a `String` or a `Symbol`, while `OPTIONS` is a `Hash`.

Below you can find some examples of params definition using `param` method:

```ruby
class UsersController < ApplicationController
  # specify that :query param is a string, so that it will automatically be converted to string
  param :query, type: :string
  # specify that :page param is a number, which will be defaulted to 1 and will have 1 as lower limit
  param :page, type: :number, default: 1, min: 1
  # specify that :per_page param is a number, which will be defaulted to 15 and will enforce the value to be in a range between 1 and 200
  param :per_page, type: :number, default: 15, clamp: 1..200
  def index
    # ... your code ...
  end

  # specify that :id param is a number and cannot be missing or blank
  param :id, type: :number, allow_blank: false
  def show
    # ... your code ...
  end

  param :id, type: :number, allow_blank: false
  # Sometimes you may want to specify a scope for the parameters, because you might have
  # nested params, like `params[:user][:name]`
  scope :user do
    param :name, type: :string, allow_blank: false
    # For string params you can set a format regexp validation, which will be automatically applied
    param :email, type: :string, required: true, format: URI::MailTo::EMAIL_REGEXP,
                  modifier: ->(v) { v.strip.downcase }
    param :birth_date, type: :date, required: true, max: DateTime.now
  end
  # You can also specify the scope inline
  param :preferences, scope: :user, type: :object, default: {}, allow_blank: false
  def update
    # ... your code ...
  end
end
```

### Available param types

`Pastore::Params` supports the following param types:

| Param type | Aliases | Description |
|------------|---------|-------------|
| `:string`   |         | Accepts string values or converts other value types to string. |
| `:number`   | `integer`, `float` | Accepts integer values or tries to convert string to number. |
| `:boolean`  |         | Accepts boolean values or tries to convert string to boolean. |
| `:date`     |         | Accepts date values or tries to convert string or number (unix time) to date. |
| `:object`   |         | Accepts object (`Hash`) values or tries to convert JSON string to object. |
| `:any`      |         | Accepts any value. |

### Avaliable options

There're several generic options that can be used with all param types, which are listed below:

| Option | Value type | Default | Description |
|--------|------------|---------|-------------|
| `:type` | `symbol`, `string`, `Class` | `:any` | Specifies the type of the parameter. |
| `:scope` | `symbol`, `string`, `symbol[]`, `string[]` | `nil` | Specifies the scope of the parameter, which is necessary for nested params definition like `params[:user][:email]`. |
| `:required` | `boolean` | `false` | When `true`, requires the parameter to be passed by client. |
| `:allow_blank` | `boolean` | `true` | When `false`, expects parameter's value not to be `nil` or empty. |
| `:default` | Depends on param type | `nil` | Allows to specify default value to set on parameter when parameter have not been sent by client. |
| `:modifier` | Lambda block | `nil` | Allows to specify a modifier lambda block, which will be used to modify parameter value. |
||
| **String** |
| `format` | `RegExp` | `nil` | Allows to use a custom `RegExp` to validate parameter value. |
||
| **Number** |
| `min` | `integer`, `float` | `nil` | Allows to specify a minimum value for the parameter. |
| `max` | `integer`, `float` | `nil` | Allows to specify a maximum value for the parameter. |
| `clamp` | `Range`, `integer[2]`, `float[2]` | `[-Float::INFINITY, Float::INFINITY]` | Allows to specify a lower and upper bound for the param value, so that a value outside the bounds will be forced to the nearest bound value. |
||
| **Date** |
| `min` | `Date`, `DateTime`, `Time`, `Integer`, `Float` | `nil` | Allows to specify a minimum value for the parameter. |
| `max` | `Date`, `DateTime`, `Time`, `Integer`, `Float` | `nil` | Allows to specify a maximum value for the parameter. |
| `clamp` | `Range`, `Date[2]`, `DateTime[2]`, `Time[2]`, `Integer[2]`, `Float[2]` | `nil` | Allows to specify a lower and upper bound for the param value, so that a value outside the bounds will be forced to the nearest bound value. |
