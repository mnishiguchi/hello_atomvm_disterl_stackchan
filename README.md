<!--
SPDX-FileCopyrightText: 2026 piyopiyo.ex members

SPDX-License-Identifier: Apache-2.0
-->

# hello_atomvm_disterl

ESP32 上で Wi-Fi 接続、SNTP による時刻同期、分散 Erlang を試すための AtomVM サンプルです。

このサンプルでは、次の動作を確認できます。

- 環境変数から Wi-Fi 情報を受け取って NVS に保存する
- Wi-Fi 接続後に SNTP で時刻同期する
- IP アドレス取得後に分散 Erlang ノードを起動する
- 定期的にローカル時刻をシリアルへ出力する
- ホスト PC の IEx から `Node.connect/1` や `:erpc.call/4` で接続する

現在は AtomVM 0.7 系の機能が必要なため、`mix atomvm.esp32.install` ではなく、このリポジトリーに含まれているカスタム AtomVM イメージを使ってください。

参考情報:

- AtomVM の `main` ドキュメントには分散 Erlang の専用ガイドがあります
  - https://doc.atomvm.org/main/distributed-erlang.html
- AtomVM の unreleased changelog には、distribution 関連の追加や修正が含まれています
  - https://doc.atomvm.org/main/CHANGELOG.html

補足:

- 2026-04-23 時点では、安定版 `release-0.6` 系ドキュメントには分散 Erlang の公開ガイドが見当たりませんでした
- そのため、この README では「`disterl` を使うには unreleased 側の AtomVM が必要」という前提で案内しています

## 対象機材

- AtomVM が対応する `ESP32` 開発ボード
- AtomVM が対応する `ESP32-S3` 開発ボード

このリポジトリーでは現在、`atomvm-esp32-elixir.img` と `atomvm-esp32s3-elixir.img` を同梱しています。

## 対象開発環境

本サンプルでは、次の環境を想定しています。

- macOS または Linux
- データ転送に対応した USB ケーブル
- Elixir
- `mix` (Elixir プロジェクトのビルドや書き込みに使うコマンド)
- `esptool` (`ESP32` / `ESP32-S3` にイメージを書き込むためのツール)
- `tio` (シリアルログを確認するためのツール)

## 使い方

このディレクトリーに移動します。

```sh
cd hello_atomvm_disterl
```

依存関係を取得します。

```sh
mix deps.get
```

このサンプル用の AtomVM イメージがまだ書き込まれていない場合は、先に次を実行してください。
すでに書き込み済みの場合は、この手順は不要です。

このリポジトリーでは現在 `ESP32` 用と `ESP32-S3` 用のイメージを同梱しています。書き込み例は次のとおりです。

ESP32 の例:

```sh
# フラッシュ全体を消去して、まっさらな状態にする
esptool --chip esp32 --port /dev/ttyACM0 erase-flash

# このサンプル用の AtomVM イメージを 0x1000 から書き込む
esptool --chip esp32 --port /dev/ttyACM0 write-flash 0x1000 atomvm-esp32-elixir.img
```

ESP32-S3 の例:

```sh
# フラッシュ全体を消去して、まっさらな状態にする
esptool --chip esp32s3 --port /dev/ttyACM0 erase-flash

# このサンプル用の AtomVM イメージを 0x0 から書き込む
esptool --chip esp32s3 --port /dev/ttyACM0 write-flash 0x0 atomvm-esp32s3-elixir.img
```

これらのオフセットは AtomVM 公式ドキュメントの Getting Started Guide にある bootloader start address に合わせています。

- https://doc.atomvm.org/main/getting-started-guide.html

アプリケーションを書き込む前に Wi-Fi 情報を設定します。

```sh
export ATOMVM_WIFI_SSID="your-ssid"
export ATOMVM_WIFI_PASSPHRASE="your-passphrase"
```

必要に応じて、起動のたびに NVS 上の Wi-Fi 情報を上書きできます。

```sh
export ATOMVM_WIFI_FORCE=true
```

アプリケーションを書き込みます。

```sh
mix atomvm.esp32.flash --port /dev/ttyACM0
```

接続先は必要に応じて読み替えてください。

例:

- Linux: `/dev/ttyACM0`, `/dev/ttyUSB0`
- macOS: `/dev/cu.usbmodemXXXX`, `/dev/cu.usbserialXXXX`

接続先が分からない場合は、次で確認できます。

```sh
tio --list
```

## 動作確認

別端末でシリアルログを開きます。

```sh
tio /dev/ttyACM0
```

Wi-Fi 接続に成功すると、次のようなログが表示されます。

```text
wifi: first-time provision (stored Wi-Fi credentials in NVS)
wifi: connected to AP
wifi: got IP {{192,168,1,123},{255,255,255,0},{192,168,1,1}}
disterl: started
disterl: node :"piyopiyo@192.168.1.123"
disterl: cookie <<"AtomVM">>
disterl: registered process :disterl
sntp: synced {tv_sec, tv_usec}
Date: 2026/01/23 21:42:01 (1737636121000ms) JST
```

## リモート接続

ESP32 側でノード名が表示されたら、ホスト PC で IEx をノード名付きで起動します。
`YOUR_HOST_LAN_IP` には、ESP32 と同じネットワーク上にあるホスト PC の IP アドレスを指定してください。

```sh
# 必要ならホスト PC の IP アドレスを確認
hostname -I

# ホスト側のノードを起動
iex --name host@YOUR_HOST_LAN_IP --cookie AtomVM
```

次に IEx 上で ESP32 ノードへ接続します。`YOUR_ESP32_IP` には、シリアルログに表示された ESP32 側の IP アドレスを指定してください。

```elixir
# 接続先のノード名
device = :"piyopiyo@YOUR_ESP32_IP"

# 接続を試す
Node.connect(device)

# 接続済みノードを確認
Node.list(:connected)

# リモート関数呼び出しを試す
:erpc.call(device, SampleApp.DistErl, :hello, [])

# メッセージ送信を試す
send({:disterl, device}, :demo_message)
```

期待される動作:

- `Node.connect(device)` が `true` を返す
- `Node.list(:connected)` に `device` が含まれる
- `:erpc.call(device, SampleApp.DistErl, :hello, [])` が `{:hello_from_atomvm, :"piyopiyo@192.168.1.123"}` のような値を返す
- `send({:disterl, device}, :demo_message)` により ESP32 側で `disterl: received :demo_message` が表示される

## Wi-Fi プロビジョニング

Wi-Fi 情報は起動時に NVS へ保存され、次回以降の起動でも再利用されます。

### 環境変数

| 環境変数 | NVS キー | 説明 |
| -------- | -------- | ---- |
| `ATOMVM_WIFI_SSID` | `wifi_ssid` | 保存する Wi-Fi SSID |
| `ATOMVM_WIFI_PASSPHRASE` | `wifi_passphrase` | 保存する Wi-Fi パスフレーズ。オープンネットワークでは省略可 |
| `ATOMVM_WIFI_FORCE` | — | 設定されていると、起動時に認証情報を上書きする |

### 挙動

- 初回起動時
  - `ATOMVM_WIFI_SSID` が設定されていれば NVS に保存される
- 2 回目以降の起動
  - NVS に保存済みの情報を再利用する
- `ATOMVM_WIFI_FORCE` を設定した場合
  - 起動のたびに NVS の認証情報を上書きする
  - パスフレーズ未指定で上書きすると、既存のパスフレーズは削除される
