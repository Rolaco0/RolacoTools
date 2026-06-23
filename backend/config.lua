local config = {
    WEBKIT_DIR_NAME = "RolacoTools",
    WEB_UI_JS_FILE = "RolacoTools.js",
    WEB_UI_ICON_FILE = "RolacoTools-icon.png",

    DEFAULT_HEADERS = {
        ["Accept"] = "application/json",
        ["X-Requested-With"] = "SteamDB",
        ["User-Agent"] = "https://github.com/BossSloth/Steam-SteamDB-extension",
        ["Origin"] = "https://github.com/BossSloth/Steam-SteamDB-extension",
        ["Sec-Fetch-Dest"] = "empty",
        ["Sec-Fetch-Mode"] = "cors",
        ["Sec-Fetch-Site"] = "cross-site",
    },

    API_MANIFEST_URL = "https://raw.githubusercontent.com/Rolaco0/lt_api_links-main/refs/heads/main/load_free_manifest_apis",
    API_MANIFEST_PROXY_URL = "https://RolacoTools.vercel.app/load_free_manifest_apis",
    API_JSON_FILE = "api.json",

    UPDATE_CONFIG_FILE = "update.json",
    UPDATE_PENDING_ZIP = "update_pending.zip",
    UPDATE_PENDING_INFO = "update_pending.json",

    HTTP_TIMEOUT_SECONDS = 15,
    HTTP_PROXY_TIMEOUT_SECONDS = 15,

    UPDATE_CHECK_INTERVAL_SECONDS = 2 * 60 * 60, -- 2 hours

    USER_AGENT = "discord(dot)gg/mGU77b9X7",

    LOADED_APPS_FILE = "loadedappids.txt",
    APPID_LOG_FILE = "appidlogs.txt",
}

return config
