/** Encrypted local storage contract — never store trading credentials. */
export const SECURE_KEYS = ["refresh_token", "device_fingerprint", "biometric_enabled"] as const;
export const FORBIDDEN_KEYS = ["mt5_password", "strategy", "magic_number", "order_ticket"] as const;
