import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { classify, markAsNoise } from "../src/pipeline";
import { resolveOverlayPath, appendNoiseSender } from "../src/overlay";

function tmpOverlay(): string {
  const dir = mkdtempSync(join(tmpdir(), "mailsift-"));
  const p = join(dir, "noise_senders.overlay");
  writeFileSync(p, "", "utf8");
  return p;
}

describe("classify", () => {
  it("drops known noise senders", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    writeFileSync(process.env.NOISE_OVERLAY_FILE, "spam@example.com\n", "utf8");
    expect(classify([{ from: "spam@example.com", subject: "x", body: "y" }])).toHaveLength(0);
  });

  it("keeps unknown senders", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    expect(classify([{ from: "ok@example.com", subject: "x", body: "y" }])).toHaveLength(1);
  });

  it("respects BATCH_SIZE", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    process.env.BATCH_SIZE = "1";
    const msgs = [
      { from: "a@example.com", subject: "", body: "" },
      { from: "b@example.com", subject: "", body: "" },
    ];
    expect(classify(msgs)).toHaveLength(1);
  });
});

describe("markAsNoise", () => {
  it("appends to the overlay", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    markAsNoise("new@example.com");
    expect(resolveOverlayPath()).toBe(process.env.NOISE_OVERLAY_FILE);
  });

  it("is idempotent across calls", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    markAsNoise("dup@example.com");
    markAsNoise("dup@example.com");
    expect(resolveOverlayPath()).toBeTruthy();
  });
});

describe("rules.yaml protection", () => {
  it("refuses when overlay resolves to rules.yaml", () => {
    process.env.CONFIG_DIR = mkdtempSync(join(tmpdir(), "cfg-"));
    process.env.NOISE_OVERLAY_FILE = join(process.env.CONFIG_DIR, "rules.yaml");
    writeFileSync(process.env.NOISE_OVERLAY_FILE, "", "utf8");
    expect(() => appendNoiseSender("x@example.com")).toThrow(/refusing/);
  });

  it("allows a distinct overlay path", () => {
    process.env.NOISE_OVERLAY_FILE = tmpOverlay();
    expect(() => appendNoiseSender("y@example.com")).not.toThrow();
  });

  it("refuses a case-variant alias on case-insensitive volumes", () => {
    process.env.CONFIG_DIR = mkdtempSync(join(tmpdir(), "cfg-"));
    process.env.NOISE_OVERLAY_FILE = join(process.env.CONFIG_DIR, "Rules.yaml");
    writeFileSync(join(process.env.CONFIG_DIR, "rules.yaml"), "", "utf8");
    expect(() => appendNoiseSender("z@example.com")).toThrow(/refusing/);
  });
});
