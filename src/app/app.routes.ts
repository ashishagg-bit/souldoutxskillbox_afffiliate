import { Routes } from "@angular/router";

export const routes: Routes = [
  { path: "", pathMatch: "full", redirectTo: "more" },
  {
    path: "more",
    loadComponent: () => import("./features/more/more-page.component").then((m) => m.MorePageComponent),
  },
  {
    path: "gigs",
    loadComponent: () =>
      import("./features/gigs-landing/gigs-landing.component").then((m) => m.GigsLandingComponent),
  },
  {
    path: "gigs/apply",
    loadComponent: () =>
      import("./features/apply/apply-wizard.component").then((m) => m.ApplyWizardComponent),
  },
  {
    path: "gigs/status",
    loadComponent: () =>
      import("./features/application-status/application-status.component").then(
        (m) => m.ApplicationStatusComponent,
      ),
  },
  {
    path: "gigs/dashboard",
    loadComponent: () =>
      import("./features/dashboard/gigs-dashboard.component").then((m) => m.GigsDashboardComponent),
  },
  { path: "**", redirectTo: "more" },
];
