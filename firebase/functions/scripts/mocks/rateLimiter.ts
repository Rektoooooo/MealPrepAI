/**
 * Mock rateLimiter — always allows requests.
 */

export const RATE_LIMITS = {
  'generate-plan': { limit: 5, windowHours: 24 },
  'swap-meal': { limit: 20, windowHours: 24 },
  'substitute-ingredient': { limit: 30, windowHours: 24 },
};

export type RateLimitEndpoint = keyof typeof RATE_LIMITS;

interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetTime: Date;
  limit: number;
}

const mockResult: RateLimitResult = {
  allowed: true,
  remaining: 5,
  resetTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
  limit: 5,
};

export async function checkRateLimit(
  _deviceId: string,
  _endpoint: RateLimitEndpoint
): Promise<RateLimitResult> {
  return { ...mockResult };
}

export async function incrementRateLimit(
  _deviceId: string,
  _endpoint: RateLimitEndpoint
): Promise<RateLimitResult> {
  return { ...mockResult, remaining: mockResult.remaining - 1 };
}

export async function getRateLimitStatus(
  _deviceId: string,
  _endpoint: RateLimitEndpoint
): Promise<RateLimitResult> {
  return { ...mockResult };
}

export async function cleanupExpiredRateLimits(): Promise<number> {
  return 0;
}
