#!/bin/bash
files_and_paths=(
  ".config/karabiner:~/.config/karabiner"
  ".config/wezterm:~/.config/wezterm"
  ".config/yabai:~/.config/yabai"
  ".config/skhd:~/.config/skhd"
  ".config/starship.toml:~/.config/starship.toml"
  ".gitconfig:~/.gitconfig"
)

create_symlink() {
  local source_file=$(realpath "$1")
  local destination_path="$2"
  
  # チルダを展開
  destination_path="${destination_path/#\~/$HOME}"
  
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
