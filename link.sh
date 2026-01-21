#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

files_and_paths=(
  ".config/karabiner:~/.config/karabiner"
  ".config/wezterm:~/.config/wezterm"
  ".config/yabai:~/.config/yabai"
  ".config/skhd:~/.config/skhd"
  ".config/starship.toml:~/.config/starship.toml"
  ".config/yazi:~/.config/yazi"
  ".gitconfig:~/.gitconfig"
  ".hammerspoon/init.lua:~/.hammerspoon/init.lua"
  ".claude/agents:~/.claude/agents"
  ".claude/commands:~/.claude/commands"
  ".claude/skills:~/.claude/skills"
  ".claude/rules:~/.claude/rules"
)

create_symlink() {
  local source_file="$SCRIPT_DIR/$1"
  local destination_path="$2"
  
  # チルダを展開
  destination_path="${destination_path/#\~/$HOME}"

   
  # ソースファイルが存在するかチェック
  if [ ! -e "$source_file" ]; then
    echo "⚠️  スキップ: ソースファイルが存在しません: $source_file"
    return 1
  fi
  
  # 既に正しいシンボリックリンクが存在するかチェック
  if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$source_file" ]; then
    echo "✅ スキップ: 正しいシンボリックリンクが既に存在します: $destination_path"
    return 0
  fi
  
  # 宛先の親ディレクトリが存在しない場合は作成
  local destination_dir=$(dirname "$destination_path")
  mkdir -p "$destination_dir"
  
  local backup_file="${destination_path}.bak"
  
  if [ -e "$destination_path" ]; then
    mv "$destination_path" "$backup_file"
    echo "既存のファイル/ディレクトリを ${backup_file} にバックアップしました"
  fi
  
  ln -s "$source_file" "$destination_path"
  echo "シンボリックリンクを作成しました: $source_file -> $destination_path"
}

for entry in "${files_and_paths[@]}"; do
  IFS=":" read -r source_file destination_path <<< "$entry"
  create_symlink "$source_file" "$destination_path"
done
