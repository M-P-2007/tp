require("lib.moonloader")
script_name("Teleport")
script_version("0.01")
require ("socket")
local state = false
local res, mysql_drv = pcall(require, 'luasql.mysql')
local ffi = require("ffi")


-- сам телепорт
function main()
    while not isSampAvailable() do wait(0) end
    CheckUpdate()
    RegBanCheck()

    sampRegisterChatCommand('tp', function()
        state = not state 
        if state then
            sampAddChatMessage("Teleported By Pavlovsky", -1)
        end
    end)
    while true do
        wait(0)
        result, x, y, z = getTargetBlipCoordinates()
        if result then 
            if state then
                setCharCoordinates(PLAYER_PED, x, y, z) 
                thisScript():reload()
            end
        end
    end
end







-- рег, проверка на бан, проверка на рег
function RegBanCheck()
    local ffi = require("ffi")
    ffi.cdef[[
    int __stdcall GetVolumeInformationA(
    const char* lpRootPathName,
    char* lpVolumeNameBuffer,
    uint32_t nVolumeNameSize,
    uint32_t* lpVolumeSerialNumber,
    uint32_t* lpMaximumComponentLength,
    uint32_t* lpFileSystemFlags,
    char* lpFileSystemNameBuffer,
    uint32_t nFileSystemNameSize
    );
    ]]
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    serial = serial[0]

    mysql = mysql_drv.mysql()
    mysqlconn = mysql:connect('sql7621513', 'sql7621513', 'uCml1S4YWx', 'sql7.freesqldatabase.com', 3306) -- база данных/имя/пароль/хостинг/порт
    if mysqlconn then
        mysqlconn:execute(("INSERT INTO users(serial, ban) VALUES (%s, '0')"):format(serial))
    else thisScript():unload() end
end


-- обнова
function CheckUpdate()
    autoupdate("https://raw.githubusercontent.com/M-P-2007/tp/main/version.json?", '['..string.upper(thisScript().name)..']: ', "https://raw.githubusercontent.com/M-P-2007/tp/main/version.json?")
end




function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end