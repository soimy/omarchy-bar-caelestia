-- Merge into ~/.config/hypr/looknfeel.lua after other appearance settings.
-- 6px desktop frame + 8px visible gap; the left bar reserves its own width.
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = { top = 14, right = 14, bottom = 14, left = 8 },
  },
  decoration = {
    rounding = 12,
    rounding_power = 2.0,
  },
})
