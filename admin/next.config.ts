import type { NextConfig } from 'next';

const config: NextConfig = {
  // The console renders live operational data. A stale client cache here means
  // an admin acts on a queue that was already cleared, so both windows are 0.
  experimental: { staleTimes: { dynamic: 0, static: 0 } },
};

export default config;
