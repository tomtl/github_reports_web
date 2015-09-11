ActiveSupport::Notifications.subscribe('request.faraday') do |name, start_time, end_time, _, env|
  http_method = env.method.to_s.upcase

  if env.status
    duration = end_time - start_time
    Rails.logger.info '[%s] %s %s %d (%.3f s)' % [env.url.host, http_method, env.url.request_uri, env.status, duration]
  else
    Rails.logger.info '[%s] %s %s request aborted by cache' % [env.url.host, http_method, env.url.request_uri]
  end
end

