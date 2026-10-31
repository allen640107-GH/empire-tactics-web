# 帝國戰記 SRPG v15 — CREDITS / 素材授權

## 字型
- LXGW WenKai TC（霞鶩文楷 TC）WenKaiTC.ttf — SIL Open Font License 1.1（序章、標題使用）。
- Noto Serif TC — SIL Open Font License 1.1。

## 音樂（v15 新增，assets/v15/bgm/*.ogg）
- title / camp / prebattle / battle_a / battle_b / battle_c / boss / final / victory：本專案以 Python（midiutil）程式作曲之原創 MIDI，
  使用 TinySoundFont（MIT License, Bernhard Schelling）＋ GeneralUser GS SoundFont（S. Christian Collins，自由授權，可用於商業作品）離線渲染，
  尾音回捲處理成無縫循環 OGG。遊戲內交叉淡入切換。原創音樂，可自由使用。

## 語音（v15 新增，assets/v15/vo/*.ogg，共 131 檔）
- 以 sherpa-onnx（Apache-2.0）離線執行 vits-icefall-zh-aishell3 模型（icefall, Apache-2.0；訓練資料 AISHELL-3, Apache-2.0）合成，
  每角色使用不同說話人＋ffmpeg 變調、喊叫 EQ、壓縮、殘響處理。完全離線、免費。

## 圖像／特效
- 標題、序章背景與 UI 框（v15）：程式／AI 生成之原創圖像。
- 魔法序列幀特效 fx_*.png、元素圖示 el_*.png、狀態圖示 st_*.png：Python/PIL 程序化生成，原創。
- 角色立繪施法格（第15–18格）修正：由自製待機格重建。


## v14 (2026-10-27)
- 60 件職業專屬防具（a31–a90）圖示：Python/PIL 程式繪製，原創，可商用。
- 升級音樂 lvup_fanfare.wav：程式合成，原創。
- 地形貼圖 t_sand / t_cobble / t_forest / t_plains / t_sandstone（512² 無縫）：Python 程序化生成（t_sandstone 衍生自自製 t_cliff），原創。
- 特效貼圖 ring.png / streak.png / star.png：Python 程序化生成，原創。
- 武器變體立繪（rain_gs、grey_ga、gard_sw）與武器遮罩 *_wm.png：衍生自 v13 自製立繪，原創。
- 立繪細節強化（受光邊、背光陰影、銳化）：程式處理自製立繪。
- 城牆塔樓、沙漠岩柱、仙人掌／棕櫚／枯樹、三層遠山、衝擊環／光柱魔法特效：Godot 程式生成，無外部素材。
