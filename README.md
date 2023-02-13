# Pastore

[![Maintainability](https://api.codeclimate.com/v1/badges/8f203ba7696c063e9cd2/maintainability)](https://codeclimate.com/github/demetra-it/pastore/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8f203ba7696c063e9cd2/test_coverage)](https://codeclimate.com/github/demetra-it/pastore/test_coverage)

Pastore is a powerful gem for Rails that simplifies the process of validating parameters and controlling access to actions in your controllers.
With Pastore, you can easily define validations for your parameters, ensuring that they meet specific requirements before being passed to your controller actions.
Additionally, Pastore allows you to easily control access to your actions, ensuring that only authorized users can access sensitive information.
With its intuitive interface and robust features, Pastore is a must-have tool for any Rails developer looking to improve the security and reliability of their application.

## Requirements

- Ruby >= 2.6
- Rails >= 5.x

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add pastore
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install pastore
```

## Usage

Pastore gem implements 2 main features: `Guards` and `Params`. Guards are intended to be used for action access control, while `Params` are intended to be used for actions params validation.

You can find more about `Params` and `Guards` by following the links below:

* **[Guards docs](./docs/Guards.md)**
* **[Params docs](./docs/Params.md)**

## `Pastore::Params` usage

`Pastore::Params` is the module that provides the features for params validation in Rails controllers. It allows you to define the params with their data type (`string`, `number`, `boolean`, `date` and `object`), specify which params are mandatory and cannot be blank.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/demetra-it/pastore>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/demetra-it/pastore/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pastore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pastore/blob/master/CODE_OF_CONDUCT.md).
