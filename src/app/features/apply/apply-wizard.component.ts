import { Component, inject, signal } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { Router } from "@angular/router";
import { StepProgressComponent } from "../../shared/step-progress/step-progress.component";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { CITY_OPTIONS, CONTENT_FORMAT_OPTIONS, NICHE_OPTIONS, PLATFORM_OPTIONS } from "../../core/data/options";
import type { City, ContentFormat, Niche, Platform } from "../../core/lib/types";

const TOTAL_STEPS = 4;

@Component({
  selector: "app-apply-wizard",
  standalone: true,
  imports: [FormsModule, StepProgressComponent],
  templateUrl: "./apply-wizard.component.html",
})
export class ApplyWizardComponent {
  private readonly router = inject(Router);
  readonly appState = inject(ApplicationStateService);

  readonly step = signal(1);
  readonly totalSteps = TOTAL_STEPS;

  readonly platformOptions = PLATFORM_OPTIONS;
  readonly cityOptions = CITY_OPTIONS;
  readonly nicheOptions = NICHE_OPTIONS;
  readonly contentFormatOptions = CONTENT_FORMAT_OPTIONS;

  readonly uploadedFileName = signal<string | null>(null);

  get application() {
    return this.appState.application();
  }

  isPlatformSelected(platform: Platform) {
    return this.application.socials.platforms.includes(platform);
  }

  togglePlatform(platform: Platform) {
    this.appState.togglePlatform(platform);
  }

  onHandleInput(value: string) {
    this.appState.setInstagramHandle(value.replace(/^@/, ""));
    if (value.trim() && !this.isPlatformSelected("Instagram")) {
      this.appState.togglePlatform("Instagram");
    }
  }

  selectCity(city: City) {
    this.appState.setCity(city);
  }

  selectNiche(niche: Niche) {
    this.appState.setNiche(niche);
  }

  selectContentFormat(format: ContentFormat) {
    this.appState.setContentFormat(format);
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) {
      this.uploadedFileName.set(file.name);
      this.appState.setInsights({ screenshotFileName: file.name });
    }
  }

  updateFollowers(value: string) {
    this.appState.setInsights({ followers: Number(value) || 0 });
  }

  updateEngagement(value: string) {
    this.appState.setInsights({ engagementRate: Number(value) || 0 });
  }

  updateAudienceIndia(value: string) {
    this.appState.setInsights({ audienceIndiaPercent: Number(value) || 0 });
  }

  get canContinueStep1() {
    return this.application.socials.instagramHandle.trim().length > 0;
  }

  get canContinueStep2() {
    return !!this.application.locationNiche.city && !!this.application.locationNiche.niche;
  }

  get canContinueStep3() {
    const i = this.application.insights;
    return i.followers > 0 && i.engagementRate > 0 && !!i.contentFormat;
  }

  goBack() {
    if (this.step() === 1) {
      this.router.navigateByUrl("/gigs");
    } else {
      this.step.update((s) => s - 1);
    }
  }

  goNext() {
    if (this.step() < TOTAL_STEPS) {
      this.step.update((s) => s + 1);
    }
  }

  submit() {
    this.appState.submitApplication();
    this.router.navigateByUrl("/gigs/status");
  }
}
