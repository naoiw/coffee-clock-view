# Coffee Clock

CoffeeScript と HTML Canvas で作ったブラウザ時計です。時刻の変化をリングとアニメーションで表現します。

## 主な機能

- 時・分・秒を3本のリングで表示
- 時刻に合わせて変化する配色
- 毎分の切り替わりに発生する粒子エフェクト
- デジタル時刻と日付の表示
- スマートフォン・高解像度ディスプレイ対応、動きを減らすOS設定への対応

## 公開先

| 環境 | ブランチ | URL |
| --- | --- | --- |
| 本番 | `main` | https://naoiw.github.io/coffee-clock-view/ |
| 開発プレビュー | `develop` | https://naoiw.github.io/coffee-clock-view/develop/ |

本番とプレビューは、1つの GitHub Pages サイト（`github-pages` 環境）内の別々のパスで公開します。

## 技術スタック

- **CoffeeScript 2** — アプリケーションロジック（このプロジェクトの実装ルール）
- **HTML / CSS / Canvas API** — 画面構成・描画
- **Node.js 22 / pnpm 9** — 開発・ビルド
- **GitHub Actions / GitHub Pages** — テスト・デプロイ

## ローカル開発

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm dev    # ビルドして http://localhost:3000 で起動
pnpm test   # 自動テスト
pnpm build  # 本番用ファイルを dist/ に生成
```

`pnpm dev` はファイル変更を自動監視しません。変更後は `pnpm build` を再実行してください。生成物（`dist/`）は Git 管理対象外です。

## ブランチ運用

1. 通常の実装・修正は `develop` で行い、`main` は本番用として維持します。
2. Pull Request ではテストとビルドを実行し、デプロイは行いません。
3. `develop` への push は検証成功後、`main` 側のワークフローから開発プレビューに反映します。
4. 本番反映は **`develop` → `main` の Pull Request** で行います。マージ後も `develop` は削除せず、`main` と同期して使い続けます。

## ディレクトリ構成

- `index.html` — 画面のエントリポイント
- `src/` — CoffeeScript の処理と CSS
- `tests/` — 自動テスト
- `.github/workflows/` — 検証・GitHub Pages デプロイ設定
- `docs/` — 設計ドキュメント

## ドキュメント

- [設計・デプロイ構成](docs/architecture.md)

## ライセンス

[MIT License](LICENSE)
