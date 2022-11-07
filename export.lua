dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

function unmuteAllTracks()
  local nbTracks = reaper.CountTracks();
    local nbTracksFound = 0
    for i=1,nbTracks do
      retval = ultraschall.SetTracksSelected(tostring(i), true)
      retval, TrackStateChunk = ultraschall.SetTrackMuteSoloState(i, 0, 0, 0) -- set mute:false, solo:false
    end
end 

function selectTracksByKeyword(_keyword)

  unmuteAllTracks();
  
  local nbTracks = reaper.CountTracks();
  local nbTracksFound = 0
  local selectedTrackString=""
  for i=1,nbTracks do
    -- get track infos and check if the name contains the keyword
    local trackName = ultraschall.GetTrackName(i)
    
    local s, e = string.find(trackName, _keyword)
    
    -- set the currently searched track to SOLO and unmute it
    if s ~= nil then
      nbTracksFound = nbTracksFound + 1
      print("found track " .. trackName)
      selectedTrackString = selectedTrackString .. i .. "," -- collect the tracks which shall be selected later
      retval, TrackStateChunk = ultraschall.SetTrackMuteSoloState(i, 0, 1, 0) -- set mute:false, solo:true
    end
  end 
  
  print("select tracks: " .. selectedTrackString);
  retval = ultraschall.SetTracksSelected(selectedTrackString, true)
  
  if nbTracksFound == 0 then
    print("!!!   No track found with keyword: " .. _keyword .. "   !!!")
  end
  
end

function renderFile(_filename, _source)
  local dir = reaper.GetProjectPath("")
  dir = string.gsub(dir, "Recordings", "") -- remove "Recordings" from the path

  addToProj = false
  renderCloseWhenDone = true
  fileNameIncrease = false
  RenderTable = ultraschall.CreateNewRenderTable()
  RenderTable["RenderFile"]=dir
  RenderTable["RenderString"]=ultraschall.CreateRenderCFG_FLAC(0, 5)
  RenderTable["Source"]=_source
  RenderTable["Bounds"]=1 --0: custom (start/end are used), 1: entire project
  RenderTable["Startposition"]=0
  RenderTable["Endposition"]=-1
  RenderTable["RenderPattern"]=_filename
  RenderTable["SilentlyIncrementFilename"]=true
  retval, dirty = ultraschall.ApplyRenderTable_Project(RenderTable)

  count, chunkArray, fileArray = ultraschall.RenderProject_RenderTable(nil, _renderTable, addToProj, renderCloseWhenDone, fileNameIncrease)
  
  -- print the generated filenames
  for i=1, #fileArray do
    print(fileArray[i])
  end
  
end

reaper.CSurf_OnPlayRateChange(1.0) -- for editing i usually set it to 1.5, so here i reset it to 1.0 for the export

-- render Foreground Tracks
selectTracksByKeyword("FG")
renderFile("$project-foreground.flac", 0)

-- render Background Tracks
selectTracksByKeyword("BG")
renderFile("$project-background.flac", 0)

-- render Speaker Tracks
selectTracksByKeyword("Speaker")
renderFile("$project-$track.flac", 3)
