#!/usr/bin/env python3
"""Demo: badge state logic for 13 realms."""
def get_badge_states(current_realm):
    realms = ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]
    names  = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]

    if current_realm not in realms:
        return f"境界 '{current_realm}' 不存在"

    idx = realms.index(current_realm)
    lit_count = idx + 1

    lines = [f"当前境界：{names[idx]}（{current_realm}）"]
    lines.append(f"点亮：{lit_count}/13 枚")
    lines.append("-" * 28)

    parts = []
    for i, (ch, nm) in enumerate(zip(realms, names)):
        icon = "✨" if i <= idx else "🌫️"
        tag = "【当前】" if i == idx else ("已过" if i < idx else "")
        parts.append(f"{icon}{ch}({nm}){tag}")

    lines.append("  ".join(parts))
    return "\n".join(lines)

# Test cases
for r in ["气", "丹", "金", "道"]:
    print(get_badge_states(r))
    print()
