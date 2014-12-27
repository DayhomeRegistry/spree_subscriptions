#Spree Subscriptions

This is a spree extension to enable adding a subscription as a product for use in the normal checkout pipeline.

## Installation

Add this line to your gemfile:

```shell
gem 'spree_subscriptions', :git => 'git@github.com:DayhomeRegistry/spree_subscriptions.git', :branch => 'master'
```

The following terminal commands will copy the migration files to the corresponding directory in your Rails application and apply the migrations to your database.

```shell
bundle exec rails g spree_subscriptions:install
bundle exec rake db:migrate
```

Then set any preferences.

