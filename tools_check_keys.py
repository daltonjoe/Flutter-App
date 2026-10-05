import json, glob, os, io

def flat(o, p=""):
    out = {}
    if isinstance(o, dict):
        for k, v in o.items():
            out.update(flat(v, f"{p}.{k}" if p else k))
    else:
        out[p] = o
    return out

data = {}
for f in glob.glob("locales/*.json"):
    code = os.path.splitext(os.path.basename(f))[0]
    with io.open(f, encoding="utf-8-sig") as fh:
        data[code] = flat(json.load(fh))

en = data["en"]
for code, d in sorted(data.items()):
    missing = [k for k in en if k not in d]
    same_en = [k for k in en if k in d and d[k] == en[k] and code != "en" and isinstance(en[k], str) and len(en[k]) > 3]
    print(f"{code}: keys={len(d)} missing_vs_en={len(missing)} identical_to_en={len(same_en)}")
    for k in missing[:8]:
        print("   MISSING", k)
    for k in same_en:
        if k.startswith(("onboarding.link_account", "onboarding.chart_save_failed")):
            print("   PLACEHOLDER?", k)