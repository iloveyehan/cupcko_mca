#!/usr/bin/env python3
# fill_items_db2.py
"""
根据 spellID 反查 itemID 并写回 data.lua。
数据来源: wago.tools 的 WoW DB2 官方数据 (ItemEffect + ItemXItemEffect)。
关系: 物品的 Use 法术 == 坐骑召唤法术 (spellID), 即 ItemEffect.SpellID == spellID,
      再通过 ItemXItemEffect 反查到 ItemID。
比 selenium 抓 wowhead 更快更准 (wowhead 对自动化请求返回 403)。

用法:
    python fill_items_db2.py data.lua            # 处理并写回 (自动备份 .bak)
    python fill_items_db2.py data.lua --dry-run  # 只打印不写
"""
import urllib.request, ssl, csv, io, re, sys, os, shutil, argparse

UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120 Safari/537.36')
CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=180, context=CTX) as r:
        return r.read().decode('utf-8', 'ignore')

def build_spell_to_items():
    """spellID -> 排序后的 [itemID,...]"""
    ie = fetch('https://wago.tools/db2/ItemEffect/csv')
    ixe = fetch('https://wago.tools/db2/ItemXItemEffect/csv')
    spell2eff = {}
    for row in csv.DictReader(io.StringIO(ie)):
        spell2eff.setdefault(int(row['SpellID']), set()).add(int(row['ID']))
    eff2item = {}
    for row in csv.DictReader(io.StringIO(ixe)):
        eff2item.setdefault(int(row['ItemEffectID']), set()).add(int(row['ItemID']))
    out = {}
    for sp, effs in spell2eff.items():
        items = set()
        for e in effs:
            items |= eff2item.get(e, set())
        if items:
            out[sp] = sorted(items)
    return out

RE_ENTRY = re.compile(r'\[(\d+)\]\s*=\s*\{\s*itemID\s*=\s*(\d+)([^}]*)\}')

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lua')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    src = open(args.lua, encoding='utf-8').read()
    print('下载 DB2 (ItemEffect + ItemXItemEffect) ...')
    m = build_spell_to_items()
    print(f'  已建立 {len(m)} 条 spell->item 映射\n')

    filled = 0
    left_zero = []
    mismatches = []
    new_lines = []
    for line in src.splitlines(True):
        em = RE_ENTRY.search(line)
        if not em:
            new_lines.append(line)
            continue
        sp = int(em.group(1))
        old_item = int(em.group(2))
        items = m.get(sp, [])
        if items:
            new_item = items[0]
            if len(items) > 1:
                print(f'  ! spell {sp} 多个 item: {items}, 取首个 {new_item}')
            # 替换 itemID=旧值 -> 新值 (仅本行)
            line2 = re.sub(
                r'(\[' + str(sp) + r'\]\s*=\s*\{\s*itemID\s*=\s*)\d+',
                lambda mm: mm.group(1) + str(new_item),
                line, count=1)
            new_lines.append(line2)
            if new_item != old_item:
                filled += 1
            if old_item not in (0, new_item) and old_item not in items:
                mismatches.append((sp, old_item, new_item))
        else:
            new_lines.append(line)
            left_zero.append(sp)

    new_src = ''.join(new_lines)

    # 写后验证: 重新解析, 确认每个 spell 的 itemID 与预期一致
    verify_ok = True
    for em in RE_ENTRY.finditer(new_src):
        sp = int(em.group(1)); got = int(em.group(2))
        expect = (m.get(sp) or [0])[0]
        if got != expect:
            verify_ok = False
            print(f'  验证失败 spell {sp}: 文件={got} 预期={expect}')
    print(f'\n写后验证: {"通过" if verify_ok else "失败!!"}')

    print(f'已填入/更新 itemID: {filled} 条')
    print(f'无 item, 保持 0: {left_zero}')

    if args.dry_run:
        print('\n--dry-run, 未写文件。')
        return
    if not verify_ok:
        print('\n验证未通过, 中止写入 (data.lua 未改动)。')
        sys.exit(1)

    bak = args.lua + '.bak'
    shutil.copy2(args.lua, bak)
    print(f'\n已备份原文件 -> {bak}')
    with open(args.lua, 'w', encoding='utf-8') as f:
        f.write(new_src)
    print(f'已写回 {args.lua}')

if __name__ == '__main__':
    main()
