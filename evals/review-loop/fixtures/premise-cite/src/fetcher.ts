import { decode, DecodeResult } from "./decoder";

const MAX_ATTEMPTS = 5;

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

export async function fetchPage(url: string): Promise<DecodeResult> {
  let attempt = 0;
  for (;;) {
    const res = await fetch(url);
    const out = await decode(res);
    if (out.status !== 429 || attempt >= MAX_ATTEMPTS) return out;
    attempt += 1;
    await sleep(2000);
  }
}
