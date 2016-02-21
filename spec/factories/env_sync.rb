require 'factory_girl'

FactoryGirl.define do
  factory :env_sync, class: Dotgpg::Heroku do
    SAME ||= {'A' => 1, 'B' => 2 }
    ADDED ||= {'A' => 1, 'B' => 2, 'C' => 3}
    REMOVED ||= {'A' => 1 }
    CHANGED ||= {'A' => 4, 'B' => 5}
    ADDED_REMOVED ||= { 'A' => 1, 'C' => 3}
    ADDED_CHANGED_REMOVED ||= { 'A' => 4, 'C' => 3}

    skip_create

    after(:build) do |env_sync, evaluator|

      # setup our fake stage object
      def env_sync.stage
        s = Object.new
        s.define_singleton_method(:app) do
          'test-app'
        end
        s.define_singleton_method(:name) do
          'test'
        end
        s.define_singleton_method(:heroku) do
          HerokuSan::API.new
        end
        s
      end

      def env_sync.heroku_config
        SAME.clone
      end

      def env_sync.dotgpg_config
        SAME.clone
      end

    end

    factory :env_sync_added do
      after(:build) do |env_sync, evaluator|
        def env_sync.dotgpg_config
          ADDED.clone
        end
      end
    end

    factory :env_sync_added_removed do
      after(:build) do |env_sync, evaluator|
        def env_sync.dotgpg_config
          ADDED_REMOVED.clone
        end
      end
    end

    factory :env_sync_added_changed do
      after(:build) do |env_sync, evaluator|
        def env_sync.dotgpg_config
          ADDED.clone.merge CHANGED.clone
        end
      end

      factory :env_sync_added_changed_removed do
        after(:build) do |env_sync, evaluator|
          def env_sync.dotgpg_config
            ADDED_CHANGED_REMOVED.clone
          end
        end
      end

    end

    factory :env_sync_changed do
      after(:build) do |env_sync, evaluator|
        def env_sync.dotgpg_config
          CHANGED.clone
        end
      end

      factory :env_sync_changed_removed do
        after(:build) do |env_sync, evaluator|
          def env_sync.heroku_config
            REMOVED.clone
          end
        end
      end
    end

    factory :env_sync_removed do
      after(:build) do |env_sync, evaluator|
        def env_sync.dotgpg_config
          REMOVED.clone
        end
      end
    end

  end
end

