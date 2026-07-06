import { Component } from "@angular/core";
import { RouterLink } from "@angular/router";
import { PhoneShellComponent } from "../../shared/phone-shell/phone-shell.component";

@Component({
  selector: "app-more-page",
  standalone: true,
  imports: [RouterLink, PhoneShellComponent],
  templateUrl: "./more-page.component.html",
})
export class MorePageComponent {
  readonly plainTiles = [
    { label: "Profile", icon: "user" },
    { label: "My Tickets", icon: "ticket" },
    { label: "Settings", icon: "settings" },
    { label: "Invite Friends", icon: "share" },
    { label: "Ticket Scanner", icon: "scan" },
    { label: "Manage Sales", icon: "chart" },
  ];
}
