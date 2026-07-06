import { Component, inject } from "@angular/core";
import { Router } from "@angular/router";
import { PhoneShellComponent } from "../../shared/phone-shell/phone-shell.component";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { TierSettingsService } from "../../core/state/tier-settings.service";

@Component({
  selector: "app-gigs-landing",
  standalone: true,
  imports: [PhoneShellComponent],
  templateUrl: "./gigs-landing.component.html",
})
export class GigsLandingComponent {
  private readonly router = inject(Router);
  private readonly appState = inject(ApplicationStateService);
  private readonly tierSettings = inject(TierSettingsService);

  readonly tierBands = this.tierSettings.tierBands;

  readonly categories = [
    {
      title: "Event attendance",
      desc: "Get on guest lists or VIP. Your presence = crowd quality signal.",
      icon: "user",
      bg: "bg-orange-50",
      stroke: "#c2410c",
    },
    {
      title: "Story coverage",
      desc: "Live stories during events. Real-time reach for organisers.",
      icon: "globe",
      bg: "bg-blue-50",
      stroke: "#1d4ed8",
    },
    {
      title: "UGC content",
      desc: "Create reels, posts, or ads for Skillbox and organiser brands.",
      icon: "video",
      bg: "bg-emerald-50",
      stroke: "#047857",
    },
    {
      title: "Brand campaigns",
      desc: "Longer-form brand deals posted by organisers directly.",
      icon: "heart",
      bg: "bg-purple-50",
      stroke: "#7e22ce",
    },
  ];

  goToApply() {
    const status = this.appState.application().status;
    if (status === "approved") {
      this.router.navigateByUrl("/gigs/dashboard");
    } else if (status === "under_review" || status === "rejected") {
      this.router.navigateByUrl("/gigs/status");
    } else {
      this.router.navigateByUrl("/gigs/apply");
    }
  }
}
