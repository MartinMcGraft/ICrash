// PIN hashes in the app's format (app/lib/src/services/pin_hasher.dart):
// `pbkdf2-sha256$<iterations>$<salt base64>$<hash base64>`, PBKDF2-HMAC-SHA256,
// 16-byte random salt, 32-byte key. Used by the seed scripts and by
// firebase/tools/set_password.mjs. DB3: PINs are set by the administration.
import { pbkdf2Sync, randomBytes } from 'node:crypto';

export const PIN_ITERATIONS = 60000; // keep equal to PinHasher.defaultIterations

export function hashPin(pin, iterations = PIN_ITERATIONS) {
  if (!/^\d{4}$/.test(pin)) throw new Error('A PIN is exactly 4 digits.');
  const salt = randomBytes(16);
  const hash = pbkdf2Sync(pin, salt, iterations, 32, 'sha256');
  return `pbkdf2-sha256$${iterations}$${salt.toString('base64')}$${hash.toString('base64')}`;
}
