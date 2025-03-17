#!/bin/bash

# 必要なディレクトリに移動
cd /usr/local/bin/

# wsdd.pyをダウンロード
wget https://raw.githubusercontent.com/kairu-8264/wsdd/master/src/wsdd.py

# wsdd.pyに実行権限を付与
chmod 755 wsdd.py

# シンボリックリンクの作成
ln -sf wsdd.py wsdd

# サービスファイルの作成
bash -c 'cat > /etc/systemd/system/wsdd.service <<EOF
[Unit]
Description=Web Services Dynamic Discovery host daemon
Requires=network-online.target
After=network.target network-online.target multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/wsdd -d WORKGROUP

[Install]
WantedBy=multi-user.target
EOF'

# サービスのリロードと有効化
systemctl daemon-reload
systemctl enable wsdd
systemctl start wsdd

echo "wsddのインストールと設定が完了しました。"
