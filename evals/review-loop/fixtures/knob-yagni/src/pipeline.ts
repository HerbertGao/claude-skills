import { loadRules } from "./rules";
import { appendNoiseSender, resolveOverlayPath } from "./overlay";
import { readFileSync } from "node:fs";

const BATCH_SIZE = Number(process.env.BATCH_SIZE ?? "200");
const SMTP_HOST = process.env.SMTP_HOST ?? "localhost";

export interface Message {
  from: string;
  subject: string;
  body: string;
}

function noiseSenders(): Set<string> {
  const overlay = readFileSync(resolveOverlayPath(), "utf8");
  return new Set(overlay.split("\n").filter(Boolean));
}

export function classify(messages: Message[]): Message[] {
  const rules = loadRules();
  const noise = noiseSenders();
  return messages
    .slice(0, BATCH_SIZE)
    .filter((m) => !noise.has(m.from) && !rules.includes(m.from));
}

export function markAsNoise(addr: string): void {
  appendNoiseSender(addr);
}

export function relayHost(): string {
  return SMTP_HOST;
}
