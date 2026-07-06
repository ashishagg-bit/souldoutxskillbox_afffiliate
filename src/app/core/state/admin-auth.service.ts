import { Injectable, signal } from "@angular/core";

const SESSION_KEY = "skillbox.affiliate.admin-session.v1";

/**
 * THIS IS NOT REAL SECURITY. It's a single shared passphrase compared
 * client-side, visible to anyone who reads the deployed JS bundle - it only
 * stops casual/accidental access to a public demo link, nothing more. Real
 * staff auth (accounts, roles, server-side session checks) needs to come
 * from the Laravel backend - see docs/api-spec.md's "Admin endpoints"
 * section, which already assumes real auth in front of every admin route.
 *
 * Change this before sharing the deployed link with anyone.
 */
const ADMIN_PASSPHRASE = "skillbox2026";

@Injectable({ providedIn: "root" })
export class AdminAuthService {
  private readonly state = signal<boolean>(sessionStorage.getItem(SESSION_KEY) === "true");

  readonly isAuthenticated = this.state.asReadonly();

  login(passphrase: string): boolean {
    const ok = passphrase === ADMIN_PASSPHRASE;
    if (ok) {
      this.state.set(true);
      sessionStorage.setItem(SESSION_KEY, "true");
    }
    return ok;
  }

  logout() {
    this.state.set(false);
    sessionStorage.removeItem(SESSION_KEY);
  }
}
