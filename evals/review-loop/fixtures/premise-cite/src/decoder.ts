export interface DecodeResult {
  status: number;
  items: unknown[];
  cursor?: string;
}

/**
 * 把上游响应解成 DecodeResult。
 * 非 2xx 一律返回空 items，由调用方按 status 决定重试。
 */
export async function decode(res: Response): Promise<DecodeResult> {
  if (res.status !== 200) {
    return { status: res.status, items: [] };
  }
  const body = (await res.json()) as { data: unknown[]; next?: string };
  return { status: 200, items: body.data, cursor: body.next };
}
