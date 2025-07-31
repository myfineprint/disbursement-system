# typed: true
# frozen_string_literal: true

require 'active_job/railtie'
require 'active_model/railtie'
require 'active_record/railtie'
require 'active_support/core_ext/integer/time'
require 'bootsnap/setup'
require 'bundler/setup'
require 'json'
require 'rails'
require 'sidekiq-cron'
require 'sidekiq/web'
require 'socket'
