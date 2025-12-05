# frozen_string_literal: true

# =============================================================================
# ApplicationJob - Base Job Class with Resilience Configuration
# =============================================================================
#
# All background jobs inherit from this class, which configures default error
# handling and retry strategies for common failure scenarios.
#
# Retry Strategy:
# - Database deadlocks: Retry 3 times with 5-second delays
# - Network timeouts: Retry 3 times with exponential backoff
#
# Discard Strategy:
# - DeserializationError: Job references deleted records - safe to skip
#
class ApplicationJob < ActiveJob::Base
  # Database deadlocks can occur under high concurrency - usually resolve on retry
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # If the job's serialized record was deleted, skip the job rather than failing
  discard_on ActiveJob::DeserializationError

  # Network issues (LLM API calls, external services) - exponential backoff
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
end
