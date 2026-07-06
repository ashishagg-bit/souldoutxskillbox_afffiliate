import { Component, input } from "@angular/core";

@Component({
  selector: "app-step-progress",
  standalone: true,
  templateUrl: "./step-progress.component.html",
})
export class StepProgressComponent {
  readonly total = input(4);
  readonly current = input(1); // 1-indexed, this step and earlier are "done"
}
