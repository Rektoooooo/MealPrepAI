/**
 * Apple Sign In Token Revocation
 *
 * Required for App Store compliance (June 2022 requirement).
 * When a user deletes their account, we must revoke their Apple Sign In token.
 *
 * Flow:
 * 1. iOS app sends the authorization code stored during Sign In with Apple
 * 2. We exchange it for a refresh token via Apple's /auth/token endpoint
 * 3. We revoke the refresh token via Apple's /auth/revoke endpoint
 *
 * Required environment variables (set via Firebase Functions config or .env):
 * - APPLE_CLIENT_ID: Your app's bundle ID (e.g., "com.mealprepai.MealPrepAI")
 * - APPLE_TEAM_ID: Your Apple Developer Team ID
 * - APPLE_KEY_ID: The Key ID for your Sign in with Apple private key
 * - APPLE_PRIVATE_KEY: The contents of your .p8 private key file (with \n for newlines)
 */

import { Request, Response } from 'express';
import * as crypto from 'crypto';

const APPLE_TOKEN_URL = 'https://appleid.apple.com/auth/token';
const APPLE_REVOKE_URL = 'https://appleid.apple.com/auth/revoke';

/**
 * Generate Apple client_secret JWT
 * Apple requires a JWT signed with your private key as the client_secret
 */
function generateClientSecret(): string {
  const teamId = process.env.APPLE_TEAM_ID;
  const clientId = process.env.APPLE_CLIENT_ID;
  const keyId = process.env.APPLE_KEY_ID;
  const privateKey = process.env.APPLE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!teamId || !clientId || !keyId || !privateKey) {
    throw new Error('Missing Apple Sign In configuration. Set APPLE_TEAM_ID, APPLE_CLIENT_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY.');
  }

  const now = Math.floor(Date.now() / 1000);

  // JWT Header
  const header = {
    alg: 'ES256',
    kid: keyId,
  };

  // JWT Payload
  const payload = {
    iss: teamId,
    iat: now,
    exp: now + 15777000, // 6 months (max allowed by Apple)
    aud: 'https://appleid.apple.com',
    sub: clientId,
  };

  // Encode header and payload
  const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  // Sign with ES256
  const sign = crypto.createSign('SHA256');
  sign.update(signingInput);
  const derSignature = sign.sign(privateKey);

  // Convert DER signature to raw r||s format for JWT
  const rawSignature = derToRaw(derSignature);
  const encodedSignature = rawSignature.toString('base64url');

  return `${signingInput}.${encodedSignature}`;
}

/**
 * Convert DER-encoded ECDSA signature to raw r||s format
 */
function derToRaw(derSig: Buffer): Buffer {
  // DER format: 0x30 [total-length] 0x02 [r-length] [r] 0x02 [s-length] [s]
  let offset = 2; // Skip 0x30 and total length
  // Skip 0x02
  offset += 1;
  const rLength = derSig[offset];
  offset += 1;
  const r = derSig.subarray(offset, offset + rLength);
  offset += rLength;
  // Skip 0x02
  offset += 1;
  const sLength = derSig[offset];
  offset += 1;
  const s = derSig.subarray(offset, offset + sLength);

  // Pad r and s to 32 bytes each
  const rPadded = Buffer.alloc(32);
  const sPadded = Buffer.alloc(32);
  r.copy(rPadded, 32 - r.length);
  s.copy(sPadded, 32 - s.length);

  return Buffer.concat([rPadded, sPadded]);
}

/**
 * Exchange authorization code for refresh token
 */
async function exchangeCodeForToken(authorizationCode: string, clientSecret: string): Promise<string> {
  const clientId = process.env.APPLE_CLIENT_ID!;

  const params = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: 'authorization_code',
  });

  const response = await fetch(APPLE_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Apple token exchange failed (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  if (!data.refresh_token) {
    throw new Error('No refresh_token in Apple response');
  }

  return data.refresh_token;
}

/**
 * Revoke the refresh token with Apple
 */
async function revokeToken(refreshToken: string, clientSecret: string): Promise<void> {
  const clientId = process.env.APPLE_CLIENT_ID!;

  const params = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    token: refreshToken,
    token_type_hint: 'refresh_token',
  });

  const response = await fetch(APPLE_REVOKE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Apple token revocation failed (${response.status}): ${errorText}`);
  }
}

/**
 * Handle POST /revokeAppleToken
 * Expects JSON body: { authorizationCode: string }
 */
export async function handleRevokeAppleToken(req: Request, res: Response): Promise<void> {
  const { authorizationCode } = req.body;

  if (!authorizationCode) {
    res.status(400).json({ success: false, error: 'Missing authorizationCode' });
    return;
  }

  try {
    const clientSecret = generateClientSecret();

    // Step 1: Exchange authorization code for refresh token
    const refreshToken = await exchangeCodeForToken(authorizationCode, clientSecret);
    console.log('Apple token exchange successful');

    // Step 2: Revoke the refresh token
    await revokeToken(refreshToken, clientSecret);
    console.log('Apple token revocation successful');

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Apple token revocation error:', error);
    res.status(500).json({
      success: false,
      error: 'Token revocation failed',
    });
  }
}
