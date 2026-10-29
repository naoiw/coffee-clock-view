# Coffee Clock

**CoffeeScript** と HTML Canvas で作ったブラウザ時計です。時・分・秒のリング、時刻によって変化する色、毎分の粒子エフェクトを表示します。スマートフォン、HiDPI、動きを減らすOS設定にも対応しています。

このプロジェクトのルールは、**アプリケーションのロジックを CoffeeScript で書くこと**です。React や TypeScript などへの移行は前提にしていません。

## 公開先

| ブランチ | 用途 | URL |
| --- | --- | --- |
| main | 本番 | https://naoiw.github.io/coffee-clock-view/ |
| develop | 開発・テスト | https://naoiw.github.io/coffee-clock-view/develop/ |

GitHub Pages は1つのサイトに両ブランチのビルド結果を配置します。develop を更新しても、本番の実装は main の内容を使います。

## ローカルで動かす

Node.js 22 / pnpm 9 を使用します。

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm run dev     # ビルドして http://localhost:3000 を起動
pnpm run check   # ビルドとテスト
```

`pnpm run dev` はファイル変更の自動監視を行いません。ソースを変更したら再度 `pnpm run build` を実行してください。生成物（`dist/`）はコミットしません。

## 開発・リリース

1. 通常の実装は `develop` で進めます。必要なら `develop` から feature ブランチを作成します。
2. Pull Requestではビルド・テストを自動実行します。
3. `develop` または `main` への push で両ブランチをビルド・テストし、GitHub Pagesに再公開します。
4. テスト版の確認後、**develop → main の Pull Request** で本番に反映します。`main` に直接 push せず、`develop` はマージ後も残します。

## ディレクトリ構成

- `index.html` — 公開ページの入口。GitHub Pages の構成上、ルートに置きます。
- `src/` — CoffeeScriptとCSSのソース。
- `tests/` — CoffeeScriptによる自動テスト。
- `.github/workflows/deploy_pages.yml` — PRのCI・本番とテストのデプロイを統合したワークフロー。
- `package.json` / `pnpm-lock.yaml` — スクリプトと依存関係。ロックファイルは再現可能なビルドのため維持します。
- `docs/architecture.md` — 描画・状態管理・公開構成の詳細設計。

