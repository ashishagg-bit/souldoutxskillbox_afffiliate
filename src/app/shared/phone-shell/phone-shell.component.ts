import { Component, input } from "@angular/core";
import { BottomNavComponent, type NavTab } from "../bottom-nav/bottom-nav.component";

@Component({
  selector: "app-phone-shell",
  standalone: true,
  imports: [BottomNavComponent],
  templateUrl: "./phone-shell.component.html",
})
export class PhoneShellComponent {
  readonly showBottomNav = input(true);
  readonly activeTab = input<NavTab>("More");
}
