--------------------------------------------------------------------------------
-- Asset Downloader for Impulse Lua
-- Downloads and extracts assets from GitHub before menu load
--------------------------------------------------------------------------------

local AssetDownloader = {}

-- Configuration
local menuRootPath = FileMgr.GetMenuRootPath()
local zipPath = menuRootPath .. "\\Lua\\ImpulseAssets.zip"
local extractPath = menuRootPath .. "\\Lua\\Impulse"
local assetsPath = menuRootPath .. "\\Lua\\Impulse\\Impulse-main"
local repoOwner = "themilkman554"
local repoName = "Impulse"
local branchName = "main"

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

--- Makes an HTTP GET request using Curl
---@param url string The URL to fetch
---@return string|nil The response body or nil on failure
local function curl_get(url)
    if not Curl then return nil end
    local curl = Curl.Easy()
    curl:Setopt(10002, url)  
    curl:Setopt(52, 1)       
    curl:Setopt(10018, "Cherax-Script")  
    curl:Setopt(64, 0) 
    curl:Setopt(81, 0) 
    
    curl:Perform()
    
    local startTime = os.time()
    local timeoutSeconds = 60 
    
    while not curl:GetFinished() do
        if os.time() - startTime > timeoutSeconds then return nil end
        Script.Yield()
    end
    
    local code, response = curl:GetResponse()
    if code == 0 then return response end
    return nil
end

local function write_file(path, data, mode)
    local f = io.open(path, mode or "w")
    if f then
        f:write(data or "")
        f:close()
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Main Logic
--------------------------------------------------------------------------------

--- Check for assets and download if missing
function AssetDownloader.CheckAssets()
    -- Check if Bookmarks.ytd already exists in Impulse-main
    local bookmarksPath = assetsPath .. "\\Textures\\Bookmarks.ytd"
    if FileMgr.DoesFileExist(bookmarksPath) then
        Logger.LogInfo("[AssetDownloader] Assets found at " .. bookmarksPath .. ". Skipping download.")
        return true
    end

    -- Show toast notification
    GUI.AddToast("Impulse Asset Loader", "Installing assets please wait...", 10000, 0)
    
    -- Wait a bit for toast to appear
    for i = 1, 30 do Script.Yield() end

    Logger.LogInfo("[AssetDownloader] Starting download from " .. repoOwner .. "/" .. repoName)

    local downloadUrl = string.format("https://codeload.github.com/%s/%s/zip/refs/heads/%s", repoOwner, repoName, branchName)
    local zipData = curl_get(downloadUrl)
    
    if not zipData then
        Logger.LogError("[AssetDownloader] Failed to download assets")
        GUI.AddToast("Impulse Asset Loader", "Download Failed! Check logs.", 5000, 0)
        return false
    end
    
    Logger.LogInfo("[AssetDownloader] Download successful via Curl. Saving to " .. zipPath)
    
    if write_file(zipPath, zipData, "wb") then
        Logger.LogInfo("[AssetDownloader] Saved zip file. Extracting...")
        if FileMgr.Unzip(zipPath, extractPath) then
            Logger.LogInfo("[AssetDownloader] Extraction successful to " .. extractPath)
            FileMgr.DeleteFile(zipPath) -- Cleanup zip
            
            if FileMgr.DoesFileExist(bookmarksPath) then
                GUI.AddToast("Impulse Asset Loader", "Assets Installed Successfully!", 3000, 0)
                Logger.LogInfo("[AssetDownloader] Assets ready at " .. assetsPath)
                return true
            else
                Logger.LogError("[AssetDownloader] Extraction succeeded but Bookmarks.ytd not found at " .. bookmarksPath)
                GUI.AddToast("Impulse Asset Loader", "Installation Error: Assets not found", 5000, 0)
                return false
            end
        else
            Logger.LogError("[AssetDownloader] Failed to unzip file.")
            GUI.AddToast("Impulse Asset Loader", "Extraction Failed!", 5000, 0)
            return false
        end
    else
        Logger.LogError("[AssetDownloader] Failed to save zip file.")
        return false
    end
end

return AssetDownloader
