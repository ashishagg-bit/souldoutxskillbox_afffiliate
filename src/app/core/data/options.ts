import type { City, ContentFormat, Niche, Platform } from "../lib/types";

export const PLATFORM_OPTIONS: Platform[] = ["Instagram", "YouTube", "Snapchat", "Twitter / X"];

export const CITY_OPTIONS: City[] = ["Delhi", "Mumbai", "Bengaluru", "Hyderabad", "Pune", "Goa", "Chennai", "Kolkata"];

export const NICHE_OPTIONS: Niche[] = ["Nightlife", "Music", "Lifestyle", "Food & Drink", "Fashion", "Travel"];

export const CONTENT_FORMAT_OPTIONS: ContentFormat[] = [
  "Reels / Short video",
  "Photos / Carousel",
  "Stories only",
  "Long-form video",
];
