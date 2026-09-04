import { createClient } from 'redis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

// In-memory fallback store when Redis instance is not reachable
const inMemoryStore = new Map<string, number>();

let redisClient: ReturnType<typeof createClient> | null = null;
let isRedisConnected = false;

export const getRedisClient = async () => {
  if (redisClient && isRedisConnected) {
    return redisClient;
  }
  if (!redisClient) {
    try {
      redisClient = createClient({ url: redisUrl });
      redisClient.on('error', (err) => {
        isRedisConnected = false;
      });
      redisClient.on('connect', () => {
        isRedisConnected = true;
      });
      await redisClient.connect();
    } catch (e) {
      isRedisConnected = false;
    }
  }
  return isRedisConnected ? redisClient : null;
};

/**
 * Checks and registers a rate-limit entry for a given key.
 * @param key Unique key e.g. ratelimit:vapi:${patientId}:${clinicId}
 * @param ttlSeconds Lockout window in seconds (defaults to 180 = 3 minutes)
 * @returns true if allowed, false if rate limited
 */
export async function checkRateLimit(key: string, ttlSeconds: number = 180): Promise<boolean> {
  try {
    const client = await getRedisClient();
    if (client) {
      // SET key "1" EX ttl NX ensures atomic check-and-set
      const result = await client.set(key, '1', {
        EX: ttlSeconds,
        NX: true,
      });
      return result === 'OK';
    }
  } catch (err) {
    // Fall back to in-memory store
  }

  const now = Date.now();
  const expiresAt = inMemoryStore.get(key);
  if (expiresAt && expiresAt > now) {
    return false;
  }

  inMemoryStore.set(key, now + ttlSeconds * 1000);
  return true;
}

/**
 * Clears a rate limit key (useful for tests or immediate resets)
 */
export async function clearRateLimit(key: string): Promise<void> {
  try {
    const client = await getRedisClient();
    if (client) {
      await client.del(key);
    }
  } catch (err) {
    // Ignore
  }
  inMemoryStore.delete(key);
}
