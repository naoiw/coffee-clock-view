# 設計メモ

## 技術選定

アプリは CoffeeScript で実装し、JavaScript のフレームワークやバンドラは使用しません。ビルドは CoffeeScript CLI に任せます。静的 HTML と CSS を利用し、外部の実行時ライブラリには依存しません。

```text
index.html              ページの構造（Pagesのルートエントリ）
src/clock.coffee        時刻計算、Canvas描画、アニメーション制御
src/styles.css          レイアウトと文字組み
tests/clock.test.coffee 主要な純粋関数のテスト
dist/                   ビルド生成物（Git 管理対象外）
.github/workflows/      CI・Pages デプロイ
```

## 時計の構造

- 時刻は閲覧者の端末のローカルタイムゾーンから取得します。
- 時針・分針・秒針は小数を含む現在時刻から進捗率を計算し、Canvas 上の円弧として表示します。
- 1分間の境界を通過したかを前フレームの分キーで判定し、粒子を1回発生させます。初回表示では発生させません。
- 粒子の更新には経過ミリ秒を使用し、フレームレート差を吸収します。大きな描画間隔は最大50msに制限します。
- Canvas の内部解像度は devicePixelRatio に追従し、最大2倍に制限します。描画座標はCSSピクセルで扱います。
- 非表示タブでは requestAnimationFrame を中断し、再表示時に再開します。
- OSの「動きを減らす」設定が有効な場合は、粒子と残像を無効にします。

## 役割分担

- **純粋関数**: 時刻成分・色相・リングの配置・粒子の移動・分の変化判定。DOM に依存せずテストできます。
- **Canvas描画**: リング・秒ドット・粒子の描画と、Canvas のリサイズ。
- **run**: DOM取得、デジタル表示、ブラウザイベント、描画ループの管理。

現状の規模では CoffeeScript を複数モジュールに分割するより、単一のエントリポイントを保つ方が簡潔です。機能が増えて責務が肥大化した時点でモジュール分割とバンドラ導入を検討します（アプリ実装は引き続き CoffeeScript とします）。

## CI・公開パイプライン

`.github/workflows/deploy_pages.yml` はPRの検証とPages公開を一元管理します。

- **Pull Request → main / develop**: 対象のPRのコードをビルドしてテストします。公開はしません。
- **Push → main / develop、および手動実行**: 各ブランチの最新コミットをチェックアウトしてビルド・テストし、GitHub Pagesへ再デプロイします。
- 両ブランチの公開物は `_site/index.html` と `_site/develop/index.html` を持つ1つの静的サイトです。HTMLは相対パスでJSとCSSを参照します。
- 別のPRのCIは独立して実行し、ページ公開は順次処理します。PRの古い検証実行は新しい実行でキャンセルします。
- ビルド時の権限は読み取りのみ、デプロイ時のみPages書き込み権限を付与します。

公開URL:

- main: `/coffee-clock-view/`
- develop: `/coffee-clock-view/develop/`

**公開環境**: main のデプロイには `github-pages`、develop からのデプロイには `github-pages-preview` を使用します。公開元は GitHub Actions です。

## リポジトリ直下のファイル

- `index.html` はルートURLでのGitHub Pages配信に使用するため、`src/` へ移動しません。
- `package.json` はCoffeeScriptコンパイル・ローカル配信・テストのスクリプトを定義します。
- `pnpm-lock.yaml` は依存パッケージのバージョンを固定し、`pnpm install --frozen-lockfile` の再現性を確保します。
- `LICENSE` は公開リポジトリのライセンス情報です。`README.md` は導入手順、`docs/` は詳細設計に分離します。
