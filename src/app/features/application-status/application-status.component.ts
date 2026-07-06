import { Component, inject } from "@angular/core";
import { Router } from "@angular/router";
import { PhoneShellComponent } from "../../shared/phone-shell/phone-shell.component";
import { ApplicationStateService } from "../../core/state/application-state.service";

@Component({
  selector: "app-application-status",
  standalone: true,
  imports: [PhoneShellComponent],
  templateUrl: "./application-status.component.html",
})
export class ApplicationStatusComponent {
  private readonly router = inject(Router);
  readonly appState = inject(ApplicationStateService);

  goToMarketplace() {
    this.router.navigateByUrl("/gigs/dashboard");
  }
}
