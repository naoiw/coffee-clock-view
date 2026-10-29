# Coffee Clock

CoffeeScript と HTML Canvas で動く、時間を眺めるための時計アプリです。

- 時・分・秒を同心円のリングで描画
- 時刻によって少しずつ変化する色
- 毎分の切り替わりに、60 個の粒子が飛び出すアニメーション
- デジタル時刻と日付を併記
- スマートフォン、高解像度ディスプレイ、動きを減らすOS設定への対応

**アプリケーションの実装言語は CoffeeScript とします。** フレームワークや TypeScript への移行を前提にはしていません。

## 公開先

| ブランチ | 用途 | URL |
| --- | --- | --- |
| main | 本番 | https://naoiw.github.io/coffee-clock-view/ |
| develop | テスト・次期バージョン | https://naoiw.github.io/coffee-clock-view/develop/ |

GitHub Pages は1つのサイトを公開します。GitHub Actions が両ブランチをビルドして、同一サイト内の異なるパスへ配置します。develop を更新しても main 側の実装は変更されません。

## 開発

Node.js 22、pnpm 9 を使用します。

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm run dev      # ビルドして localhost:3000 で表示
pnpm run check    # CoffeeScript のビルドとテスト
```

CoffeeScript のコンパイル後の JavaScript と CSS は `dist/` に生成し、Git にはコミットしません。

## ブランチ運用

1. 通常の実装・修正は **develop** で行う。必要なら develop から feature ブランチを切り、develop へのPRで統合する。
2. develop に push すると、テスト版が再デプロイされる。本番は main の内容を維持する。
3. テスト版と CI を確認してから **develop → main の Pull Request** を作成・マージする。
4. main に直接 push しない。develop はマージ後も削除しない。

実装とデプロイ方式の詳細は [docs/architecture.md](docs/architecture.md) を参照してください。
