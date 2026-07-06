import { Component, signal } from "@angular/core";
import { AdminReviewComponent } from "./admin-review.component";
import { AdminOverviewComponent } from "./admin-overview.component";
import { AdminShowsComponent } from "./admin-shows.component";
import { AdminAnalyticsComponent } from "./admin-analytics.component";
import { AdminSettingsComponent } from "./admin-settings.component";

type AdminTab = "overview" | "applications" | "shows" | "analytics" | "settings";

@Component({
  selector: "app-admin-panel",
  standalone: true,
  imports: [AdminReviewComponent, AdminOverviewComponent, AdminShowsComponent, AdminAnalyticsComponent, AdminSettingsComponent],
  templateUrl: "./admin-panel.component.html",
})
export class AdminPanelComponent {
  readonly tab = signal<AdminTab>("overview");

  readonly tabs: { id: AdminTab; label: string }[] = [
    { id: "overview", label: "Overview" },
    { id: "applications", label: "Applications" },
    { id: "shows", label: "Shows" },
    { id: "analytics", label: "Analytics" },
    { id: "settings", label: "Settings" },
  ];

  setTab(tab: AdminTab) {
    this.tab.set(tab);
  }
}
