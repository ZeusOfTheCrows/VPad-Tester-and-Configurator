-------------------------------------------------------------------------------
--               VPad Tester & Configurator by ⱿeusOfTheCrows                --
--         built upon on work by Keinta15 | Original work by Smoke5          --
-------------------------------------------------------------------------------

---------------------------------- ~globals~ ----------------------------------
-- locals marked /~\ are manipulated in code. i know it's bad practice, but i
-- find it makes more sense. also they're all marked as local - i found lots of
-- info on why locals are better and much faster, and none on why they're worse

-- global colours
local clr = {
	white  = Color.new(235, 219, 178),
	bright = Color.new(251, 241, 199),
	orange = Color.new(254, 128, 025),
	red    = Color.new(251, 073, 052),
	dRed   = Color.new(204, 036, 029, 128),
	green  = Color.new(152, 151, 026),
	grey   = Color.new(189, 174, 147),
	black  = Color.new(040, 040, 040)}--ztodo check this works

-- short button names
local btn = {
	cross    = SCE_CTRL_CROSS,
	square   = SCE_CTRL_SQUARE,
	circle   = SCE_CTRL_CIRCLE,
	triangle = SCE_CTRL_TRIANGLE,
	start    = SCE_CTRL_START,
	select   = SCE_CTRL_SELECT,
	home     = SCE_CTRL_PSBUTTON,  -- hmmm... see draw function line ~270
	rTrigger = SCE_CTRL_RTRIGGER,
	lTrigger = SCE_CTRL_LTRIGGER,
	dpUp     = SCE_CTRL_UP,
	dpDown   = SCE_CTRL_DOWN,
	dpLeft   = SCE_CTRL_LEFT,
	dpRight  = SCE_CTRL_RIGHT}  -- indent nex lines so they fold (in sublime)
	-- get system accept button–if 2^13 (13þ bit) assign circle, else cross
	btn.accept = (Controls.getEnterButton() == 8192) and btn.circle or btn.cross
	-- assign back button based on previous result
	btn.cancel = (btn.accept == btn.circle) and btn.cross or btn.circle

-- load images from files
local img = {
	bgd      = Graphics.loadImage("app0:resources/img/bgd.png"),
	cross    = Graphics.loadImage("app0:resources/img/crs.png"),
	square   = Graphics.loadImage("app0:resources/img/sqr.png"),
	circle   = Graphics.loadImage("app0:resources/img/ccl.png"),
	triangle = Graphics.loadImage("app0:resources/img/tri.png"),
	sttSelct = Graphics.loadImage("app0:resources/img/ssl.png"),
	home     = Graphics.loadImage("app0:resources/img/hom.png"),
	rTrigger = Graphics.loadImage("app0:resources/img/rtr.png"),
	lTrigger = Graphics.loadImage("app0:resources/img/ltr.png"),
	dpUp     = Graphics.loadImage("app0:resources/img/dup.png"),
	dpDown   = Graphics.loadImage("app0:resources/img/ddn.png"),
	dpLeft   = Graphics.loadImage("app0:resources/img/dlf.png"),
	dpRight  = Graphics.loadImage("app0:resources/img/drt.png"),
	analogue = Graphics.loadImage("app0:resources/img/ana.png"),
	frontTch = Graphics.loadImage("app0:resources/img/gry.png"),
	rearTch  = Graphics.loadImage("app0:resources/img/blu.png")}

-- load fonts
local varwFont = Font.load("app0:/resources/fnt/fir-san-reg.ttf")
local monoFont = Font.load("app0:/resources/fnt/fir-cod-reg.ttf")
Font.setPixelSizes(varwFont, 24)
Font.setPixelSizes(monoFont, 24)

-- audio related vars
Sound.init()  -- this is never terminated, but doing so crashes to livearea
local audiopath = "app0:resources/snd/stereo-audio-test.ogg"
local audiofile = 0  --/~\ -- ztodo: i don't think i need this here
local audioplaying = false  --/~\

-- offsets touch image to account for image size. should be half of resolution
local touchoffset = {x = 30, y = 32}
-- could be automatic, but isn't due to a bug (see lines ~380 & ~315):
-- touchoffset  = {x = Graphics.getImageWidth (img.frontTch)/2,  -- 30
                -- y = Graphics.getImageHeight(img.frontTch)/2}  -- 32
-- multiplier for analogue stick size
local anasizemulti = 7.5
-- global file handle for analogsenhancer config file
-- anaencfgprops = {}  --/~\
local anaendbg = ""  -- dbg ztodo remove
local genericdebugtext = ""  -- multipurpose global debug text ztodo remove
-- analogsenhancer config paths
local anaencfgpaths = {
	"ur0:tai/AnaEnaCfg.txt",
	"ux0:data/AnalogsEnhancer/config.txt"}
local dzstatustexts = {
	"config loaded from ",
	"cannot find file. is plugin installed?",
	"config loaded. it is recommended to set deadzones to 0 before configuring",
	"config successfully set. press start to reboot & apply changes"}

-- probably doesn't need to be a global to be persistent,
-- but i couldn't make it work
local stkMax = {lx = 0.0, ly = 0.0, rx = 0.0, ry = 0.0}  --/~\
-- for converting keyread to keydown - updates at end of frame
-- padprevframe = 0  --/~\
-- current page (0=home, 1=deadzone config, etc.)
local currPage = 0  --/~\

---------------------------- function declarations ----------------------------

local function lPad(str, len, char)  -- pad numbers, to avoid jumping text
	-- default arguments
	local len = len or 3
	local char = char or "0"
	local str = tostring(str)
	if char == nil then char = '' end
	return string.rep(char, len - #str) .. str
end

local function customToStr(arrayval, sepchars)  -- only used for debug for now
	-- i know table.concat exists, but this doesn't have a tizz when told to
	-- concatenate a string (advanced programming i know)
	local sepchars = sepchars or "; "
	-- check if is already string (not necessary, but saves headaches)
	if arrayval == nil then
		return "nil"
	elseif type(arrayval) == "string" then
		return arrayval
	elseif type(arrayval) == "boolean" then
		return arrayval and "true" or "false"
	else
		local r = ""
		local first = true  -- first iteration of loop
		for k, v in pairs(arrayval) do
			-- for first iter don't print preceding ";"
			if first then
				r = r .. k .. "," .. v
				first = false
			else
				r = r .. sepchars .. k .. "," .. v
			end
		end
		return r
	end
end

local function touchValsToTable(...)  -- readTouch values to table
	-- convert values returned from Controls.read[Retro]Touch() into
	-- coherent x = y dictionary
	local exes, wyes, rtn = {}, {}, {}
	-- assign to two separate vars
	for i, v in ipairs({...}) do
		if i%2 == 1 then
			table.insert(exes, v)
		else
			table.insert(wyes, v)
		end
	end
	-- combine x's and y's together
	for i, v in ipairs(exes) do
		rtn[v] = wyes[i]
	end
	return rtn
end

local function calcMax(currNum, currMax)  -- calculate "max" stick range 0-128
	local num = math.abs(currNum - 127)
	local max = currMax and math.abs(currMax) or 0.0  -- catch if nil
	if num > max then
		return num
	else
		return max
	end
end

local function openFile(filepaths)  -- find existing file or return false
	for i, p in ipairs(filepaths) do
		if System.doesFileExist(p) then
			--                         first 3 letters of path (for id'ing)
			return System.openFile(p, FREAD), string.sub(p,1,3)
		end
	end
	return false, ""
end

local function parseCfgFile(filepaths)  -- read config file and return info
	local anaenraw = {}  -- unparsed ana en properties
	local anaenprops = {}  -- analogs enhancer properties
	local file, partt = openFile(filepaths)  -- file handle, partition
	if file then
		file = System.readFile(file, System.sizeFile(file))
		-- match set of one or more of all alphanumeric chars
		for p in string.gmatch(file, "[%w]+") do
			table.insert(anaenraw, p)
		end
		-- this is untidy but i see no better way of doing it
		anaenprops.leftNum = anaenraw[2]         -- deadzone value
		anaenprops.leftSRS = anaenraw[3] == "y"  -- software rescaling (to bool)
		anaenprops.riteNum = anaenraw[5]
		anaenprops.riteSRS = anaenraw[6] == "y"
		anaenprops.anawide = anaenraw[7] == "y"  -- analog_wide mode (to bool)
		-- System.closeFile(file)
		return anaenprops, partt
	else
		return false, partt  -- ztodo
	end
end

local function toggleAudio()  -- no arguments because it has to be persistent?
	-- /!\ Sound.isPlaying does not work. whether 'tis my bug or native, i do
	-- /!\ not know; but once toggled twice it always returns false
	audioplaying = not audioplaying  -- toggle bool ztodo local
	-- if audiofile ~= nil?
	if audioplaying then
		-- i don't think this is great for performance, but i have to Sound.close
		-- the file as Sound.pause doesn't consistently pause
		audiofile = Sound.open(audiopath)
		Sound.play(audiofile)
	else
		-- Sound.stop(audiofile)  -- why is this not a valid function? i need it
		-- pause then close to update Sound.isPlaying(). it doesn't work, and is
		-- probably unnecessary, but it seems uncouth to close it whilst playing
		Sound.pause(audiofile)
		-- close to prevent bug of overlapping audio
		Sound.close(audiofile)
	end
end

------------------------------ drawing functions ------------------------------

local function drawDecs(batt)  -- draw decorations (title, frame, battery, etc)
	-- colour background & draw bg image
	-- Graphics.fillRect(0, 960, 0, 544, clr.black)
	Graphics.drawImage(0, 40, img.bgd)

	-- draw header info
	Font.print(varwFont, 008, 004,
		"VPad Tester & Configurator v1.3.0 by ZeusOfTheCrows", clr.orange)
	Font.print(monoFont, 904, 004,  batt.pct .. "%", batt.clr)
end

local function drawHomePage()
	-- Display info
	Font.print(varwFont, 205, 078, "press Start + Select to exit", clr.grey)
	Font.print(varwFont, 205, 103,
		"press L + R to reset max stick range", clr.grey)
	Font.print(varwFont, 205, 128, "press Χ + Ο for audio test", clr.grey)
	Font.print(varwFont, 205, 153, "press Δ + Π for deadzone config", clr.grey)
	Font.print(varwFont, 205, 178, genericdebugtext, clr.grey)
end

local function drawDzcfPage(statustext, statuscolour)  -- deadzone config page
	local statuscolour = clr.grey or statuscolour
	-- Display info
	Font.print(varwFont, 205, 078, customToStr(statustext, "; "), statuscolour)
	Font.print(varwFont, 205, 103, "press L to reset max stick range", clr.grey)
	Font.print(varwFont, 205, 128, "press Δ to toggle software rescaling [NYI]", clr.grey)
	Font.print(varwFont, 205, 153, "press Π to toggle analog_wide [NYI]", clr.grey)
	-- debug print
	-- Font.print(varwFont, 205, 178, "placeholder", clr.grey)
end

local function drawBtnInput(pad)  -- all digital buttons

	--[[ bitmask
		1      select
		2      ?
		4      ?
		8      start
		16     dpad up
		32     dpad right
		64     dpad down
		128    dpad left
		256    l trigger
		512    r trigger
		1024   ?
		2048   ?
		4096   triangle
		8192   circle
		16384  cross
		32768  square
	]]

	-- for i in table if convert buttons to table ztodo

	--  Draw buttons if pressed
	if Controls.check(pad, btn.circle) then
		Graphics.drawImage(888, 169, img.circle)
	end
	if Controls.check(pad, btn.cross) then
		Graphics.drawImage(849, 207, img.cross)
	end
	if Controls.check(pad, btn.triangle) then
		Graphics.drawImage(849, 130, img.triangle)
	end
	if Controls.check(pad, btn.square) then
		Graphics.drawImage(812, 169, img.square)
	end

	if Controls.check(pad, btn.select) then
		Graphics.drawImage(807, 378, img.sttSelct)
	end
	if Controls.check(pad, btn.start) then
		Graphics.drawImage(858, 378, img.sttSelct)
	end
	if Controls.check(pad, btn.home) then
		-- this only gets called whilst the home button is enabled. this means
		-- i can't use Controls.lockHomeButton():
		Graphics.drawImage(087, 376, img.home)
	end

	if Controls.check(pad, btn.lTrigger) then
		Graphics.drawImage(068, 043, img.lTrigger)
	end
	if Controls.check(pad, btn.rTrigger) then
		Graphics.drawImage(775, 043, img.rTrigger)
	end

	-- i don't use drawRotateImage due a bug (maybe in vita2d) that draws the
	-- images incorrectly (fuzzy broken borders, misplaced pixels). if you're
	-- editing this in the future, check if it's been fixed to reduce vpk size
	if Controls.check(pad, btn.dpUp) then
		-- Graphics.drawRotateImage(97, 158, dpupimg, 0)
		Graphics.drawImage(077, 134, img.dpUp)
	end
	if Controls.check(pad, btn.dpDown) then
		-- Graphics.drawRotateImage(98, 216, dpupimg, 3.141593)
		Graphics.drawImage(077, 193, img.dpDown)
	end
	if Controls.check(pad, btn.dpLeft) then
		-- Graphics.drawRotateImage(69, 188, dpupimg, 4.712389)
		Graphics.drawImage(044, 167, img.dpLeft)
	end
	if Controls.check(pad, btn.dpRight) then
		-- Graphics.drawRotateImage(128, 187, dpupimg, 1.570796)
		Graphics.drawImage(103, 167, img.dpRight)
	end
end

local function drawSticks(stkVals)  -- fullsize analogue sticks
	-- draw and move analogue sticks on screen
	-- default position: 90, 270 (-(128/anasizemulti)
	Graphics.drawImage(
		(073 + (stkVals.lx / anasizemulti)),
		(252 + (stkVals.ly / anasizemulti)),
		img.analogue)

	-- default position: 810, 270
	Graphics.drawImage(
		(793 + (stkVals.rx / anasizemulti)),
		(252 + (stkVals.ry / anasizemulti)),
		img.analogue)
end

local function drawStickText(stkVals)  -- bottom two lines of info numbers
	Font.print(monoFont, 010, 480,
	       "Left: " .. lPad(stkVals.lx) .. ", " .. lPad(stkVals.ly) ..
	       "\nMax:  " .. lPad(stkMax.lx) .. ", " .. lPad(stkMax.ly), clr.white)
	Font.print(monoFont, 670, 482,
	       "Right: " .. lPad(stkVals.rx) .. ", " .. lPad(stkVals.ry) ..
	       "\nMax:   " .. lPad(stkMax.rx) .. ", " .. lPad(stkMax.ry), clr.white)
end

local function drawMiniSticks(stkVals)  -- smaller stick circle for dz cfg
	-- draw recommended deadzones 137, 300
	Graphics.fillCircle(124, 304,
	                   ((math.max(stkMax.lx, stkMax.ly)*0.3) + 4), clr.dRed)
	Graphics.fillCircle(844, 304,
	                   ((math.max(stkMax.rx, stkMax.ry)*0.3) + 4), clr.dRed)

	-- default position: 124, 304 (-(128/3.33†)) †stick movement multiplier
	Graphics.fillCircle(
	        (086 + stkVals.lx / 3.33), (266 + stkVals.ly / 3.33), 4, clr.bright)
	-- default position: 844, 304
	Graphics.fillCircle(
	        (806 + stkVals.rx / 3.33), (266 + stkVals.ry / 3.33), 4, clr.bright)
end

local function drawTouch(fronttouch, reartouch)  -- front/rear touch thumbprint
	for x, y in pairs(fronttouch) do
		if x ~= nil then  -- /!\ N.B. x/y are not equivalent to table.x/y
			Graphics.drawImage(x - touchoffset.x, y - touchoffset.y, img.frontTch)
			-- Graphics.drawImage(x - Graphics.getImageWidth (img.frontTch)/2,
			--                    y - Graphics.getImageWidth (img.frontTch)/2,
			--                    img.frontTch)
		end
	end

	for x, y in pairs(reartouch) do
		if x ~= nil then
			Graphics.drawImage(x - touchoffset.x, y - touchoffset.y, img.rearTch)
			-- Graphics.drawImage(x - Graphics.getImageWidth (img.rearTch)/2,
			                   -- y - Graphics.getImageWidth (img.rearTch)/2,
			                   -- img.rearTch)
		end
	end
end

------------------------------- main functions --------------------------------
---------------- (functions that call other smaller functions) ----------------

local function drawInfo(pad, page, stkVals,  -- ugly, but trims line length
	                     fronttouch, reartouch, batt, dzstatus)
	-- main draw function that calls others
	local page = page or 0  -- default value for current page

	-- Starting drawing phase
	-- i'm not sure clearing the screen every frame is the best way to do this,
	-- but it's the only way i know (it also breaks psvremap)
	Graphics.initBlend()
	Screen.clear(clr.black)

	drawDecs(batt)
	drawBtnInput(pad)
	drawStickText(stkVals)
	if page == 0 then
		drawHomePage()
		drawSticks(stkVals)
		drawTouch(fronttouch, reartouch)
	elseif page == 1 then
		drawDzcfPage(anaendbg)
		drawMiniSticks(stkVals)
	end

	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()  -- flip framebuffer, i guess?
end

local function homePageLogic(pad, ppf)
	-- reset stick max
	if Controls.check(pad, btn.lTrigger) and
	   Controls.check(pad, btn.rTrigger) then
		for k, v in pairs(stkMax) do
			stkMax[k] = 0.0
		end
	end

	-- Sound Testing
	-- this is the mess that comes of not having a keydown event
	if (Controls.check(pad, btn.cross) and
	   (Controls.check(pad, btn.circle) and not
	    Controls.check(ppf, btn.circle))) or
	   (Controls.check(pad, btn.circle) and
	   (Controls.check(pad, btn.cross) and not
	    Controls.check(ppf, btn.cross))) then
		toggleAudio()
	end

	if (Controls.check(pad, btn.square) and
	   (Controls.check(pad, btn.triangle) and not
	    Controls.check(ppf, btn.triangle))) or
	   (Controls.check(pad, btn.triangle) and
	   (Controls.check(pad, btn.square) and not
	    Controls.check(ppf, btn.square))) then
		currPage = 1
		anaendbg, dzstatus = parseCfgFile(anaencfgpaths)
	end

	if Controls.check(pad, btn.start) and Controls.check(pad, btn.select) then
		System.exit()
	end

	-- toggle homebutton lock (can't make it work)
	-- if Controls.check(pad, start) and Controls.check(pad, select) then
	-- 	if homeButtonLocked == false then
	-- 		-- lock home button and declare so
	-- 		homeButtonLocked = true
	-- 		Controls.lockHomeButton()
	-- 	else
	-- 		homeButtonLocked = false
	-- 		Controls.unlockHomeButton()
	-- 	end
	-- end
end

local function dzcfPageLogic(pad, ppf)  -- deadzone config page
	-- reset stick max
	if Controls.check(pad, btn.lTrigger) and not
	   Controls.check(ppf, btn.lTrigger) then
		for k, v in pairs(stkMax) do
			stkMax[k] = 0.0
		end
	end
	-- ztodo shoulders toggle software rescaling
	-- if Controls.check(pad, btn.lTrigger) and not
	   -- Controls.check(ppf, btn.lTrigger) then
		-- anaenprops.leftSRS = not anaenprops.leftSRS
	-- end
	-- exit page
	if(Controls.check(pad, btn.cancel) and not
	   Controls.check(ppf, btn.cancel)) then
		currPage = 0  -- for now just exit back to homescreen
	end
end

local function main(padPrevFrame)
	-- i don't know if the "main" function is a paradigm in lua, but
	-- it seems neater to me

	-- init battery stats
	local batt = {}  -- battery info
	batt.pct = System.getBatteryPercentage()
	if System.isBatteryCharging() then
		batt.clr = clr.green
	elseif batt.pct <= 18 then
		batt.clr = clr.red
	else
		batt.clr = clr.grey
	end

	-- initialise pad state this frame
	local pad = Controls.read()
	-- update sticks
	local stkVals = {}
	stkVals.lx, stkVals.ly = Controls.readLeftAnalog()
	stkVals.rx, stkVals.ry = Controls.readRightAnalog()

	-- calculate max stick values
	for k, v in pairs(stkMax) do
		stkMax[k] = calcMax(stkVals[k], stkMax[k])
	end

	-- init/update touch registration (not drawn if nil)
	local fronttouch = touchValsToTable(Controls.readTouch())
	local reartouch = touchValsToTable(Controls.readRetroTouch())

	local dzstatus = ""  -- ztodo

	if currPage == 0 then
		homePageLogic(pad, padPrevFrame)
	elseif currPage == 1 then
		dzcfPageLogic(pad, padPrevFrame)
	end

	drawInfo(pad, currPage, stkVals, fronttouch, reartouch, batt, dzstatus)

	return pad  -- see main loop
end

---------------------------------- main loop ----------------------------------
while true do
	-- take pad status from previous frame and immediately pass it back
	-- into the function (which returns the pad at the end)
	-- also make stickmax permanent
	padPrevFrame = main(padPrevFrame)
end