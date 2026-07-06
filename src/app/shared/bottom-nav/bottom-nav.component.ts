import { Component, input } from "@angular/core";
import { RouterLink } from "@angular/router";

export type NavTab = "Home" | "Events" | "Search" | "More";

@Component({
  selector: "app-bottom-nav",
  standalone: true,
  imports: [RouterLink],
  templateUrl: "./bottom-nav.component.html",
})
export class BottomNavComponent {
  readonly active = input<NavTab>("More");

  readonly tabs: { label: NavTab; link: string }[] = [
    { label: "Home", link: "/more" },
    { label: "Events", link: "/more" },
    { label: "Search", link: "/more" },
    { label: "More", link: "/more" },
  ];
}
