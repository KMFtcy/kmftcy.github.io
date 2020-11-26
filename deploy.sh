# ===
# === ENV variables
# ===
THEMES_CONFIG_FILE_NAME=themes_config.yml
BACKUP_THEMES_CONFIG_NAME=origin_themes_config.yml
SELECTED_THEME=next


# update themes submodule
git submodule init
git submodule update
# replace themes config
cp themes/${SELECTED_THEME}/_config.yml ${BACKUP_THEMES_CONFIG_NAME}
cp ${THEMES_CONFIG_FILE_NAME} themes/${SELECTED_THEME}/_config.yml
echo "===themes config changed"

# deploy blog
hexo clean && hexo g && hexo d
# restore themes config
cp ${BACKUP_THEMES_CONFIG_NAME} themes/${SELECTED_THEME}/_config.yml
rm ${BACKUP_THEMES_CONFIG_NAME}
echo "===themes config restored"