# wsdd

wsddはWebサービスディスカバリ（WSD）ホストデーモンを実装しています。これにより、Sambaホスト（ローカルNASデバイスなど）がWebサービスディスカバリクライアント（Windowsなど）によって発見されるようになります。

また、WSDプロトコルを実装した他のデバイスを検索するクライアント機能も実装しています。この操作モードは「ディスカバリーモード」と呼ばれます。


## クイックスタート

Ubuntu 18以降
```
curl -s https://raw.githubusercontent.com/kairu-8264/wsdd/master/install_wsdd.sh | bash
```


## 目的

WindowsではNetBIOSディスカバリがサポートされていないため、wsddはWebサービスディスカバリメソッドを使用してホストを再びWindowsで表示できるようにします。これにより、Sambaを実行しているNASやファイル共有サーバーなどが、Windowsの「ネットワーク」ビューに表示されるようになります。

### 背景

Windows 10 バージョン 1511以降、デフォルトでSMBv1とNetBIOSデバイスディスカバリが無効化されました。Windowsのバージョン1709（「Fall Creators Update」）以降では、SMBv1クライアントのインストールがサポートされていません。これにより、Sambaを実行しているホストは「ネットワーク」ビューに表示されなくなります。しかし、接続に問題はなく、Sambaは引き続き正常に動作しますが、ユーザーはSambaホストがWindowsで自動的に表示されることを希望するかもしれません。

「Samba自体にこの機能が含まれているべきでは？」と思うかもしれませんが、Sambaをファイル共有サービスとして使用することは、ホストがネットワークの「ネットワーク」ビューに表示されなくても可能です。ホスト名（名前解決が機能している場合）やIPアドレスを使用して接続することができます。さらに、この機能は2015年からSambaのバグトラッカーにパッチとして存在していますので、将来的にSambaに組み込まれる可能性もあります。

## 要件

wsddはPython 3.7以降でのみ動作します。Linux、FreeBSD、OpenBSD、MacOS、SunOS/Illumos上で実行できます。他のUnix（NetBSDなど）でも動作する可能性はありますが、テストは行われていません。

Samba自体はwsddには必須ではありませんが、Sambaデーモンを実行しているホストでwsddを実行する意味があります。OpenRC/GentooのinitスクリプトはSambaサービスに依存しています。

## インストール

### OSおよびディストリビューション別のインストール手順

以下のセクションでは、異なるOSディストリビューションでwsddをインストールする手順を提供します。十分な権限があることを前提としています（rootまたはsudoを使用）。

#### Arch Linux

[AURパッケージ](https://aur.archlinux.org/wsdd.git)からwsddをインストールします。

#### CentOS, Fedora, RHEL

wsddはRedHat/CentOSのEPELリポジトリに含まれています。[EPELリポジトリをセットアップした後](https://docs.fedoraproject.org/en-US/epel/)、以下のコマンドでインストールできます。

```
dnf install wsdd
```

#### Debian系ディストリビューション（Debian、Ubuntu、Mintなど）

wsddはDebianとUbuntuの公式リポジトリ（*universe*）に含まれています。Debian 12（*Bookworm*）およびUbuntu 22.04 LTS（*Jammy Jellyfish*）以降、Linux Mint 21（*Vanessa*）以降でも利用できます。以下のコマンドでインストールできます。

```
apt install wsdd
```

#### FreeBSD

FreeBSDでは、以下のコマンドでwsddポートをインストールできます。

```
pkg install py39-wsdd
```

#### Gentoo

2つのオーバーレイを選択できます：GURUプロジェクトまたは[作者が維持している専用オーバーレイ](https://github.com/christgau/wsdd-gentoo)。

```
emerge eselect-repository eselect repository enable guru emerge --sync
```

オーバーレイをセットアップした後、以下のコマンドでwsddをインストールします。

```
emerge wsdd
```

## 一般的なインストール手順

インストールには特別な手順は必要ありません。wsdd.pyファイルを任意の場所に配置し、`wsdd`という名前に変更して、そこから実行するだけです。initスクリプト/ユニットファイルは、wsddが`/usr/bin/wsdd`またはFreeBSDの場合`/usr/local/bin/wsdd`にインストールされていることを前提としています。設定ファイルはありません。特別な権限は必要なく、非特権ユーザー（専用のユーザーを作成することが推奨されます）で実行することが推奨されます。

リポジトリの`etc`ディレクトリには、FreeBSDのrc.d、Gentooのopenrc、systemd（多くのLinuxディストリビューションで使用）など、さまざまなinit(1)システム向けのサンプル設定ファイルが含まれています。これらのファイルはテンプレートとして使用できますが、実際のディストリビューション/インストールに合わせて調整が必要です。

## 使用方法

### ファイアウォール設定

以下のポート、方向、およびアドレスに対するトラフィックを許可する必要があります。

- `239.255.255.250`（IPv4用）および`ff02::c`（IPv6用）へのUDP/3702の送受信
- 出力UDP/3702のユニキャストトラフィック
- TCP/5357への受信

UFWやfirewalldでは、各アプリケーション/サービスプロファイルがそれぞれのディレクトリに配置されています。UFWプロファイルは特定のUDPおよびTCPポートに対するトラフィックの許可のみ可能ですが、IPレンジやマルチキャストトラフィックの制限はできません。

### オプション

デフォルトでは、wsddはホストモードで実行され、すべてのインターフェースにバインドされ、警告とエラーメッセージのみが表示されます。この設定で実行されるホストは、設定されたホスト名で発見され、デフォルトのワークグループに所属します。ディスカバリーモードを有効にすると、WSD互換デバイスを検索できます。この2つのモードは同時に使用可能です。詳細は下記を参照してください。

#### 一般的なオプション

- `-4`, `--ipv4only`: IPv4のみに制限
- `-6`, `--ipv6only`: IPv6のみに制限
- `-A`, `--no-autostart`: プログラム起動時に自動でネットワーク活動を開始しない
- `-c DIRECTORY`, `--chroot DIRECTORY`: 別のディレクトリにchrootする
- `-H HOPLIMIT`, `--hoplimit HOPLIMIT`: マルチキャストパケットのホップ制限を設定
- `-i INTERFACE/ADDRESS`, `--interface INTERFACE/ADDRESS`: wsddがリスンするインターフェースまたはIPアドレスを指定
- `-l PATH/PORT`, `--listen PATH/PORT`: APIサーバーを有効にする（UnixドメインソケットまたはTCPソケット）
- `--metadata-timeout TIMEOUT`: HTTPベースのメタデータ交換のタイムアウトを設定（デフォルト2.0秒）
- `-s`, `--shortlog`: 短縮形式でログ出力

#### ホスト操作モード

ホストモードでは、wsddを実行しているデバイスがWindowsで発見されます。

- `-d DOMAIN`, `--domain DOMAIN`: ホストがADSドメインに参加している場合
- `-n HOSTNAME`, `--hostname HOSTNAME`: 使用するホスト名をオーバーライド
- `-o`, `--no-server`: ホスト操作モードを無効にする
- `-w WORKGROUP`, `--workgroup WORKGROUP`: デフォルトのワークグループ名を変更

#### クライアント/ディスカバリーモード

このモードでは、他のWSD互換デバイスを検索できます。

- `-D`, `--discovery`: ディスカバリーモードを有効にし、WSDホスト/サーバーを検索

## 使用例

- `eth0`でIPv6アドレスのみを使用する場合

```
wsdd -i eth0 -6
```

- smb.confに基づいてワークグループを設定し、詳細ログを表示

```
SMB_GROUP=$(grep -i '^\sworkgroup\s=' smb.conf | cut -f2 -d= | tr -d '[:blank:]') wsdd -v -w $SMB_GROUP
```

## 技術的説明

wsddは指定された（またはすべての）ネットワークインターフェースに対して、UDPマルチキャストソケット、ユニキャスト応答用の2つのUDPソケット、TCPリスニングソケットを作成します。各インターフェースについてこれを行います。起動時に「Hello」メッセージが送信され、終了時には「Bye」メッセージが送信されます。I/O多重化を使用して、複数のソケットからのネットワークトラフィックを単一のプロセスで処理します。

## よくある問題

### セキュリティ

wsddはセキュリティ機能（例えば、TLSを使ったHTTPサービス）は実装していません。wsddの意図された使用法は、プライベートなLAN環境での使用です。ホストのIPアドレスが「Hello」メッセージに含まれるため、発見が早くなります（「Resolve」メッセージを避ける）。

### NATでの使用

NATに影響されるインターフェースでwsddを使用しないでください。標準に従い、「ResolveMatch」メッセージにはインターフェースのIPアドレス（「トランスポートアドレス」）が含まれており、クライアント（Windowsなど）はNATの影響を受けたアドレスに接続できません。

### トンネル/ブリッジインターフェース

OpenVPNやDockerのようなトンネルやブリッジインターフェースがある場合、インターフェースを指定せずに実行すると問題が発生することがあります。この場合、`-i/--interface`オプションを使用してインターフェースを指定することで問題を回避できます。

##
