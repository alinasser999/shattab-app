import type { NextConfig } from 'next';

const config: NextConfig = {
  // The console renders live operational data. A stale client cache here means
  // an admin acts on a queue that was already cleared, so both windows are 0.
  // Next 16 requires the static window to be at least 30 seconds. All
  // operational pages remain dynamic; this only covers framework-generated
  // static output such as the not-found page.
  experimental: { staleTimes: { dynamic: 0, static: 30 } },
};

export default config;
