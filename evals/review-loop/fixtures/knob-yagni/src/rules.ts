import { join } from "node:path";
import { readFileSync } from "node:fs";

const CONFIG_DIR = process.env.CONFIG_DIR ?? "/etc/mailsift";

/**
 * operator 手工维护的规则文件。只读，任何自动路径都不得写它。
 */
export function resolveRulesPath(): string {
  return join(CONFIG_DIR, "rules.yaml");
}

export function loadRules(): string {
  return readFileSync(resolveRulesPath(), "utf8");
}
