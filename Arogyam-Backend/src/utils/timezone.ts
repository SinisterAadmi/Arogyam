/**
 * Shared Indian Standard Time (IST, UTC+5:30) timezone utilities.
 * Ensures consistent day-boundary calculations across all backend services.
 */

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000; // 5 hours 30 minutes in milliseconds

/**
 * Returns a new Date shifted by +5:30 hours to match IST.
 */
export function toIST(date: Date = new Date()): Date {
  return new Date(date.getTime() + IST_OFFSET_MS);
}

/**
 * Returns the calendar date string in IST format 'YYYY-MM-DD'.
 */
export function getISTDateString(date: Date = new Date()): string {
  const istDate = toIST(date);
  return istDate.toISOString().split('T')[0];
}

/**
 * Returns a Date object set to 00:00:00.000Z for the IST calendar date.
 * Matches the QueueToken.queueDate storage format.
 */
export function getISTMidnight(date: Date = new Date()): Date {
  const dateStr = getISTDateString(date);
  return new Date(`${dateStr}T00:00:00.000Z`);
}

/**
 * Returns UTC start and end Date objects corresponding to 00:00:00.000 and 23:59:59.999 in IST.
 */
export function getISTDayBounds(date: Date = new Date()): { start: Date; end: Date } {
  const dateStr = getISTDateString(date);
  // 00:00:00 IST is 18:30:00 UTC previous day (UTC - 5.5 hours)
  const start = new Date(new Date(`${dateStr}T00:00:00.000Z`).getTime() - IST_OFFSET_MS);
  const end = new Date(new Date(`${dateStr}T23:59:59.999Z`).getTime() - IST_OFFSET_MS);
  return { start, end };
}
