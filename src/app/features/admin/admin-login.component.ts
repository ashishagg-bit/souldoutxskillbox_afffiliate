import { Component, inject, signal } from "@angular/core";
import { Router } from "@angular/router";
import { AdminAuthService } from "../../core/state/admin-auth.service";

@Component({
  selector: "app-admin-login",
  standalone: true,
  templateUrl: "./admin-login.component.html",
})
export class AdminLoginComponent {
  private readonly auth = inject(AdminAuthService);
  private readonly router = inject(Router);

  readonly passphrase = signal("");
  readonly error = signal(false);

  submit() {
    if (this.auth.login(this.passphrase())) {
      this.router.navigateByUrl("/admin");
    } else {
      this.error.set(true);
    }
  }
}
