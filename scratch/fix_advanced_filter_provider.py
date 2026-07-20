from pathlib import Path

p = Path("lib/features/marketplace/presentation/screens/advanced_filter_screen.dart")
t = p.read_text(encoding="utf-8")
needle = "import 'package:iq_motors/features/marketplace/data/services/car_filter_service.dart';"
insert = (
    needle
    + "\n"
    + "import 'package:iq_motors/features/marketplace/presentation/providers/filter_providers.dart';"
)
if "filter_providers" not in t:
    t = t.replace(needle, insert)
t = t.replace("activeAdsProvider", "homeCarsProvider")
p.write_text(t, encoding="utf-8")
print("advanced_filter providers patched")
