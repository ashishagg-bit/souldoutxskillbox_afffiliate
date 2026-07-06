import { inject } from "@angular/core";
import { Router, type CanActivateFn } from "@angular/router";
import { AdminAuthService } from "../state/admin-auth.service";

export const adminAuthGuard: CanActivateFn = () => {
  const auth = inject(AdminAuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) {
    return true;
  }
  return router.parseUrl("/admin-login");
};
