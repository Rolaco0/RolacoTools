local m_utils = require("utils")
local fs = require("fs")
local http_client = require("http_client")
local config = require("config")
local logger = require("plugin_logger")
local paths = require("paths")
local utils = require("plugin_utils")
local steam_utils = require("steam_utils")

local auto_update = {}

local function is_windows_platform()
    local os_name = tostring(m_utils.getenv("OS") or "")
    if os_name == "Windows_NT" then return true end

    local windir = tostring(m_utils.getenv("WINDIR") or "")
    if windir ~= "" then return true end

    local ok, separator = pcall(function()
        return package.config:sub(1, 1)
    end)
    return ok and separator == "\\"
end

function auto_update.check_for_updates_now()
    local cfg_path = paths.backend_path(config.UPDATE_CONFIG_FILE)
    local cfg = utils.read_json(cfg_path)
    
    local latest_version = ""
    local zip_url = ""
    
    local gh_cfg = cfg.github
    if gh_cfg then
        local owner = gh_cfg.owner or ""
        local repo = gh_cfg.repo or ""
        local asset_name = gh_cfg.asset_name or "ltsteamplugin.zip"
        local tag = gh_cfg.tag or ""
        local tag_prefix = gh_cfg.tag_prefix or ""
        
        local endpoint = "https://api.github.com/repos/" .. owner .. "/" .. repo .. "/releases/latest"
        if tag ~= "" then
            endpoint = "https://api.github.com/repos/" .. owner .. "/" .. repo .. "/releases/tags/" .. tag
        end
        
        local resp = http_client.get(endpoint, {
            headers = {
                ["Accept"] = "application/vnd.github+json",
                ["User-Agent"] = "RolacoTools-Updater"
            },
            timeout = 10
        })
        if resp and resp.status == 200 and resp.body then
            local data = utils.decode_json(resp.body)
            local tag_name = data.tag_name or ""
            latest_version = tag_name ~= "" and tag_name or (data.name or "")
            if tag_prefix ~= "" and latest_version:sub(1, #tag_prefix) == tag_prefix then
                latest_version = latest_version:sub(#tag_prefix + 1)
            end
            
            local assets = data.assets or {}

            -- Prefer the configured legacy filename when it exists.
            for _, asset in ipairs(assets) do
                if asset.name == asset_name then
                    zip_url = asset.browser_download_url
                    break
                end
            end

            -- Releases may use versioned names such as
            -- RolacoTools-v2.2.0.zip. Select that asset before falling back
            -- to the proxy so future version names keep working.
            if zip_url == "" then
                for _, asset in ipairs(assets) do
                    local name = string.lower(tostring(asset.name or ""))
                    if name:find("rolacotools", 1, true) and name:match("%.zip$") then
                        zip_url = asset.browser_download_url or ""
                        break
                    end
                end
            end

            -- Last-resort ZIP selection for repositories with a renamed asset.
            if zip_url == "" then
                for _, asset in ipairs(assets) do
                    local name = string.lower(tostring(asset.name or ""))
                    if name:match("%.zip$") then
                        zip_url = asset.browser_download_url or ""
                        break
                    end
                end
            end

            if zip_url == "" and tag_name ~= "" then
                zip_url = "https://RolacoTools.vercel.app/api/get-plugin/" .. tag_name
            end
        end
    end
    
    if latest_version == "" or zip_url == "" then
        return { success = false, error = "Manifest missing version or zip_url" }
    end
    
    local current_version = utils.get_plugin_version()

    -- Compare version tables component by component (can't use <= on tables in Lua)
    local function compare_versions(a, b)
        local ta = utils.parse_version(a)
        local tb = utils.parse_version(b)
        local len = math.max(#ta, #tb)
        for i = 1, len do
            local ai = ta[i] or 0
            local bi = tb[i] or 0
            if ai < bi then return -1
            elseif ai > bi then return 1
            end
        end
        return 0
    end

    if compare_versions(latest_version, current_version) <= 0 then
        return { success = true, message = "Up-to-date (current " .. current_version .. ")" }
    end
    
    local pending_zip = paths.backend_path(config.UPDATE_PENDING_ZIP)

    -- Never reuse a previous or incomplete download.
    if fs.exists(pending_zip) then
        pcall(fs.remove, pending_zip)
    end
    
    local is_windows = is_windows_platform()
    local cmd
    if is_windows then
        cmd = string.format('curl.exe -fSL -A "RolacoTools-Updater" "%s" -o "%s" && tar.exe -xf "%s" -C "%s"', zip_url, pending_zip, pending_zip, paths.get_plugin_dir())
    else
        cmd = string.format('curl -fL -A "RolacoTools-Updater" -o "%s" "%s" && unzip -o -q "%s" -d "%s"', pending_zip, zip_url, pending_zip, paths.get_plugin_dir())
    end

    logger.log("RolacoTools updater: downloading " .. latest_version .. " from " .. zip_url)
    m_utils.exec(cmd)

    -- Do not report success merely because the command was launched. Verify
    -- the manifest that was actually written into the live plugin directory.
    local installed_version = utils.get_plugin_version()
    if compare_versions(installed_version, latest_version) < 0 then
        if fs.exists(pending_zip) then pcall(fs.remove, pending_zip) end
        local err = "Update extraction failed: expected " .. latest_version ..
            " but plugin.json is still " .. installed_version
        logger.error("RolacoTools updater: " .. err)
        return { success = false, error = err, currentVersion = installed_version }
    end

    if fs.exists(pending_zip) then pcall(fs.remove, pending_zip) end

    logger.log("RolacoTools updater: verified installed version " .. installed_version)
    local msg = "RolacoTools updated to " .. latest_version .. ". Please restart Steam."
    return { success = true, updated = true, version = installed_version, message = msg }
end

function auto_update.restart_steam()
    local is_windows = is_windows_platform()
    if is_windows then
        local script_path = paths.backend_path("restart_steam.cmd")
        if fs.exists(script_path) then
            m_utils.exec('start /b cmd /C "' .. script_path .. '"')
            return true
        end
    else
        m_utils.exec("killall steam && steam &")
        return true
    end
    return false
end

function auto_update.apply_pending_update_if_any()
    return ""
end

return auto_update
