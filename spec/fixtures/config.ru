# frozen_string_literal: true

run lambda { |_env| [200, { 'content-type' => 'text/plain' }, ['OK']] }
