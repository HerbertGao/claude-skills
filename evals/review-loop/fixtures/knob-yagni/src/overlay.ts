import { statSync, realpathSync, writeFileSync, readFileSync } from "node:fs";
import { resolve, dirname, basename, join } from "node:path";
import { resolveRulesPath } from "./rules";

const DATA_DIR = process.env.DATA_DIR ?? "/var/lib/mailsift";

/**
 * overlay 文件路径。机器维护，与 operator 手工维护的 rules.yaml 严格分离。
 */
export function resolveOverlayPath(): string {
  return process.env.NOISE_OVERLAY_FILE ?? join(DATA_DIR, "noise_senders.overlay");
}

/**
 * 硬 MUST：反馈路径绝不能写 rules.yaml。
 * round 3 从词法比较升级为 inode 比较 + realpath 退化分支。
 */
function isSameFile(a: string, b: string): boolean {
  const sa = statSync(a);
  const sb = statSync(b);
  if (sa.dev === sb.dev && sa.ino === sb.ino) return true;

  // 退化分支：文件可能尚未创建，回落到父目录 realpath + basename
  const pa = realpathSync(dirname(a));
  const pb = realpathSync(dirname(b));
  return pa === pb && basename(a) === basename(b);
}

export function appendNoiseSender(addr: string): void {
  const overlayPath = resolveOverlayPath();
  if (isSameFile(resolve(overlayPath), resolve(resolveRulesPath()))) {
    throw new Error("refusing to write operator-maintained rules.yaml");
  }
  const prev = readFileSync(overlayPath, "utf8");
  writeFileSync(overlayPath, prev + addr + "\n", "utf8");
}
