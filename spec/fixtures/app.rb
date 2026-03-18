# frozen_string_literal: true

App = lambda do |_env|
  [200, { 'content-type' => 'text/plain' }, ['OK']]
end
