# coffee-clock-view

Canvas 上で動く「時間アート」風の時計です。CoffeeScript で書かれた、純粋関数と副作用を分離したアニメーションの実験プロジェクトです。

## このリポジトリでやっていること

- **Canvas 時計**: ブラウザの Canvas API で、時・分・秒を円弧（リング）で表示するビジュアル時計
- **時刻に連動した色**: 現在の時・分から HSL 色を算出し、時針リングの色として使用
- **00秒の「破裂」エフェクト**: 秒が 0 になる瞬間、円周上の 60 点から色付きの粒子が放射状に飛び散り、徐々にフェードアウト
- **秒ドット**: 現在の秒数に応じて、円周上に白いドットを 1 秒ごとに表示（0 秒のときは破裂演出のため非表示）
- **背景フェード**: 毎フレーム半透明の暗色で上塗りすることで、軌跡が残るような残像表現

ビルドは CoffeeScript を JavaScript にコンパイルし、`dist/` に出力。`index.html` から `dist/clock.js` を読み込み、ローカルサーバーで表示して確認できます。

---

## clock.coffee の内部詳細

### 全体の設計方針

- **純粋関数**: 引数だけに依存し、同じ入力なら同じ出力。DOM/Canvas を触らない。
- **副作用**: `ctx` や `canvas` を渡して「描画」「リサイズ」などを行う関数として分離し、名前で区別している。
- **状態**: アニメーションループでは「前の秒」と「粒子リスト」だけを state として持ち、`tick` が state を受け取り新しい state を返す形で更新。

---

### 定数・ユーティリティ

| 名前 | 説明 |
|------|------|
| `TAU` | `Math.PI * 2`（1 周のラジアン）。円弧・角度計算で使用。 |

---

### 時間まわり（純粋）

- **`getTimeComponents(date)`**  
  - `date` から「12時間制の時」「分」「秒（小数含む）」「現在の秒の整数部分」をまとめたオブジェクトを返す。  
  - 破裂判定用に `currentSec`（`Math.floor(秒)`）を別途持たせている。

- **`timeColor(h, m)`**  
  - 時 `h` と分 `m` から HSL の色相を計算し、`"hsl(色相, 80%, 60%)"` の文字列を返す。  
  - 時針の色として使われ、時間の経過とともにゆっくり色が変化する。

---

### 座標・キャンバス（純粋 / 副作用）

- **`center(canvas)`**  
  - 純粋。`canvas` の幅・高さから中心座標を返す関数 `{ x, y }` を返す。  
  - 描画の基準点として使う。

- **`resize(canvas)`**  
  - 副作用。`canvas` のサイズを `window.innerWidth / innerHeight` に合わせる。  
  - `window` の `resize` イベントで呼ばれる。

---

### 描画（副作用）

- **`fade(ctx, w, h)`**  
  - 半透明の暗色 `rgba(14,14,17,0.25)` で全体を矩形塗り。  
  - 毎フレーム呼ぶことで、前のフレームが少しずつ残り、軌跡・残像になる。

- **`drawRing(ctx, cx, cy, radius, ratio, color, width)`**  
  - 中心 `(cx, cy)`、半径 `radius` の円の、12 時方向（`-Math.PI/2`）から `ratio`（0〜1）の割合まで円弧を描く。  
  - 時は `h/12`、分は `m/60`、秒は `s/60` を `ratio` に渡して、3 本のリングを描画。  
  - 線の色・太さは引数で指定。`lineCap: "round"` で端を丸くしている。

- **`drawSecondDots(ctx, cx, cy, sec)`**  
  - 現在の秒数 `sec` に応じて、半径 220 の円周上に白い小円を「秒の数だけ」描く。  
  - 0 秒のときはメインループ側で呼ばれない（破裂演出優先）。

---

### 秒の「破裂」粒子（純粋 + 副作用）

粒子は「不変データ」として扱い、更新のたびに新しいオブジェクトを返す設計。

- **`createParticle(x, y, angle, color)`**  
  - 純粋。位置 `(x,y)`、放射方向 `angle`、色 `color` から 1 粒子のオブジェクトを生成。  
  - 速度はランダムで少しばらつかせ、`life: 60`（約 1 秒で消える）を持つ。

- **`updateParticle(p)`**  
  - 純粋。速度 `vx, vy` で位置を 1 フレーム分進め、`life` を 1 減らした新しい粒子を返す。  
  - 元の `p` は変更しない。

- **`isAlive(p)`**  
  - 純粋。`p.life > 0` かどうかで生存判定。

- **`drawParticle(ctx, p)`**  
  - 副作用。粒子を半径 2.5 の円で描画。  
  - 色は `p.color` を `hsla` に変換し、`alpha = p.life / 60` でフェードアウトさせる。

- **`createExplosionParticles(cx, cy, color)`**  
  - 純粋。中心 `(cx, cy)`、半径 220 の円周上に 60 個の点を等間隔に取り、それぞれの位置・外向きの角度で `createParticle` を呼び、60 個の粒子の配列を返す。  
  - 色は現在の `timeColor`（時針の色）をそのまま使う。

- **`shouldExplode(prevSec, currentSec)`**  
  - 純粋。「前の秒」が存在し、かつ「前の秒 ≠ 現在の秒」かつ「現在の秒が 0」のとき `true`。  
  - つまり「ちょうど 00 秒に跨った瞬間」にだけ破裂を起こす判定。

---

### メインループと状態

- **`tick(ctx, canvas, state)`**  
  - 1 フレーム分の処理を行う。  
  - 流れ:  
    1. `state` から `lastSec` と `particles` を取り出す。  
    2. `center(canvas)` で中心座標を取得。  
    3. `fade` で背景をフェード。  
    4. `getTimeComponents(new Date())` で現在の時・分・秒を取得。  
    5. `timeColor(h, m)` でベース色を算出。  
    6. 時・分・秒の 3 本の `drawRing` を描画。  
    7. `shouldExplode(lastSec, currentSec)` が真なら、`createExplosionParticles(cx, cy, baseColor)` で新粒子を生成し、既存の `particles` に連結。そうでなければ `particles` はそのまま。  
    8. `currentSec !== 0` のときだけ `drawSecondDots` を呼ぶ。  
    9. 全粒子を `updateParticle` で更新し、それぞれ `drawParticle` で描画。  
    10. `isAlive` でフィルタし、生き残った粒子だけを新しい state の `particles` にする。  
  - 戻り値は新しい state: `{ lastSec: currentSec, particles: aliveParticles }`。

- **`run()`**  
  - エントリポイント。  
  - `#canvas` を取得し、2D コンテキストを取得。  
  - `resize` の登録と初回実行。  
  - 初期 state: `{ lastSec: null, particles: [] }`。  
  - `animate` で `state = tick(ctx, canvas, state)` を実行し、`requestAnimationFrame(animate)` でループ。  
  - 状態は `run` の閉包内の `state` だけで保持している。

---

## セットアップ・実行

```bash
pnpm install
pnpm run build   # src/clock.coffee → dist/clock.js
pnpm run serve   # ルートを http://localhost:3000 で配信
# または
pnpm start       # build + serve をまとめて実行
```

ブラウザで `http://localhost:3000` を開き、Canvas 上で時計と 00 秒の破裂エフェクトを確認できます。

## 技術スタック

- **CoffeeScript** (^2.7.0) … コンパイルのみ
- **serve** … 静的ファイル配信
- フロントは Vanilla JS（コンパイル後の JS）と HTML5 Canvas
