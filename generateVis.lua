function Initialize()
end

function GenerateHOC()
  local v = { }
  
  local match  = string.match
  local gmatch = string.gmatch
  local max    = math.max
  local min    = math.min

  for line in io.lines( SKIN:ReplaceVariables('#@#Variables.inc') ) do
    local key,val = match(line,'^([%w_]+)%s-=%s-(.-)$')
    v[key or ''] = val
  end

  v.Config = v.Config:gsub(" ","")
  local lRoot     = SKIN:GetVariable('ROOTCONFIGPATH')
  local lCommon   = lRoot..v.Config..'.ini'
  local lBands   = lRoot..'bands.inc'
  
  local function SetKV(type,sec,key,val,dst)
    SKIN:Bang(type,sec,key,val,dst)
  end
  local function SetFileKV(s,k,v,p)    SetKV('!WriteKeyValue',s,k,v,p)         end
  local function SetLiveKV(s,k,d)      SetKV('!SetOption',s,k,d,v.Config)      end
  local function SetLiveGroupKV(g,k,d) SetKV('!SetOptionGroup',g,k,d,v.Config) end
  local function clamp(n,min,max)      return math.min(max,math.max(min,n))    end

  local halfwidth = (v.Radius + v.BarHeight) * v.Scale


  bandsfile = io.open(lBands, 'w+')
  
  --###########################
  --# GENERATE AUDIO MEASURES #
  --###########################
  local bands = v.Bands-1 --zero based
  local audioMeasures = 0

  -- if we mirror the vis, then we only need half as many audio measures
  if v.Mirror == "1" then
    if (v.Bands % 2 == 0) then
      audioMeasures = bands-(v.Bands/2)
    else
      audioMeasures = (bands/2)
    end
  else
    audioMeasures = bands
  end

  print("audioMeasures: "..audioMeasures)


  for i = 0,audioMeasures,1
  do
    bandsfile:write('[Audio'..i..']\n')

    local kvBarAudio = {
      Measure              = 'Plugin',
      Plugin               = 'AudioLevelBeta',
      Parent               = 'Audio',
      Type                 = 'Band',
      Group                = 'Audio',
      AverageSize          = v.AveragingPastValuesAmount,
      BandIdx              = i
    }
    for key,val in pairs(kvBarAudio) do bandsfile:write(key..'='..val..'\n') end
  end


  --#############
  --# SMOOTHING #
  --#############
  if v.Smoothing ~= "0" then
    for i = 0,audioMeasures,1
    do
      bandsfile:write('[Calc'..i..']\n')

      local formula = '('

      for s = -v.Smoothing,v.Smoothing,1
      do
        if v.InvertMirror == '0' and v.Mirror == "1" then
          formula = formula..'Audio'..asen(i+s,0,audioMeasures)..'+'
        elseif v.InvertMirror == '1' and v.Mirror == "1" then
          formula = formula..'Audio'..sens(i+s,0,audioMeasures)..'+'
        else
          formula = formula..'Audio'..sens(i+s,0,audioMeasures)..'+'
        end
      end

      formula = formula:sub(0,formula:len()-1)
      formula = formula..')/'..(v.Smoothing*2)+1
      --formula = formula..')*1.5'

      local kvAudioCalc = {
        Measure              = 'Calc',
        Formula              = formula,
        Group                = 'Audio'
      }
      for key,val in pairs(kvAudioCalc) do bandsfile:write(key..'='..val..'\n') end
    end
  end

  local bandcolors = v.Gradient == "1" and GetGradients(v.GColor, v.Bands) or 0

  --###################
  --#  GENERATE BARS  #
  --###################

  --skip first band bc its buggy
  for i = 0,bands,1
  do

    local angle
    local a

    if v.Mirror == "1" then
      if v.InvertMirror == '1' then
        angle = v.StartAngle+((v.EndAngle/v.Bands + v.AngularDisplacement) * (i+0.5))
        a = i <= audioMeasures and i or i-audioMeasures-1
      else
        angle = v.StartAngle+((v.EndAngle/v.Bands + v.AngularDisplacement) * (i+0.5))
        a = i <= audioMeasures and i or bands-i
      end
    else
      angle = v.StartAngle+((v.EndAngle/v.Bands + v.AngularDisplacement) * (i+0.5))
      a = i
    end

    local tmatrix = GetRotationScaleMatrix(angle,halfwidth,halfwidth,v.Scale)

    bandsfile:write('['..i..']\n')


    --local red = {R=255,G=0,B=0;A=255}
    --local blue = {R=0,G=0,B=255;A=255}

    --local ppb = 100 / tonumber(v.Bands)
    --local color = GetGradientOf(red,blue,ppb * i)

    local kvBar = {
      Meter                = 'Bar',
      MeasureName          = v.Smoothing == "0" and 'Audio'..a or 'Calc'..a,
      AntiAlias            = 1,
      TransformationMatrix = tmatrix,
      X                    = halfwidth - v.BarWidth/2,
      Y                    = 0,
      W                    = v.BarWidth,
      H                    = v.BarHeight,
      BarOrientation       = 'Vertical',
      Group                = 'Bars',
      BarColor             = v.Gradient == "1" and ColorToString(bandcolors[i]) or v.SColor,
      Flip                 = v.InvertBars
    }
    for key,val in pairs(kvBar) do bandsfile:write(key..'='..val..'\n') end

    --SKIN:Bang('!UpdateMeter',  i-1,         v.Config)
    --SKIN:Bang('!UpdateMeasure','Audio'..i-1,v.Config)
  end

  bandsfile:flush()
  bandsfile:close()
  --#############################
  --# GEN. CENTRAL AUDIO PARENT #
  --#############################
  local kvAudio = {
    Bands         = audioMeasures + 1,
    FFTSize       = v.FFTSize,
    FFTBufferSize = v.FFTBufferSize,
    FFTAttack     = v.FFTAttack,
    FFTDecay      = v.FFTDecay,
    FreqMin       = v.FreqMin,
    FreqMax       = v.FreqMax,
    Sensitivity   = v.Sensitivity
  }

  for key,val in pairs(kvAudio) do SetFileKV('Audio', key, val, lCommon) end

  --######################
  --# SET BACKGROUND W/H #
  --######################

  SetFileKV('MeterBG', 'W', halfwidth*2, lCommon)
  SetFileKV('MeterBG', 'H', halfwidth*2, lCommon)

  SKIN:Bang('!Refresh')

  print("BEAT CIRCLE LOADED")

end

-- 1 2 3 1 2 3
function sens(n,min,max)
  local d = n > max and n-max or n
  return d < min and max+n+1 or d
end

-- 1 2 3 3 2 1
function asen(n,min,max)
  local d = n > max and max-(n-max) or n
  return d < min and min-(n-min) or d
end

-- abadonned function
function GenerateBands(amount,radius,maxheight,thickness,halfwidth)

  local bandsfilepath = SKIN:GetVariable('ROOTCONFIGPATH')..'bands.inc'

  halfwidth = halfwidth or radius + maxheight

  bandsfile = io.open(bandsfilepath , 'w+')

  for i = 0,amount,1
  do
  
    local x = halfwidth
    local y = 0
    local w = thickness
    local h = maxheight

    local angle = (360/amount) * i
    local tmatrix = GetRotationScaleMatrix(angle,halfwidth,halfwidth,1)

    bandsfile:write('[Audio', i, ']\n')
    bandsfile:write('Measure=Plugin\n')
    bandsfile:write('Plugin=AudioLevelBeta\n')
    bandsfile:write('Parent=Audio\n')
    bandsfile:write('Type=Band\n')
    bandsfile:write('Group=Audio\n')
    bandsfile:write('BandIdx=', i, '\n')

    bandsfile:write('[', i, ']\n')
    bandsfile:write('Meter=Bar\n')
    bandsfile:write('MeasureName=Audio',i,'\n')
    bandsfile:write('Group=Bars\n')
    bandsfile:write('BarOrientation=Vertical\n')
    bandsfile:write('BarColor=255,255,255,255\n')
    bandsfile:write('AntiAlias=1\n')
    --bandsfile:write('BarImage=#@#Images\\SpecBar.jpg\n')
    bandsfile:write('X=', x, '\n')
    bandsfile:write('Y=', y, '\n')
    bandsfile:write('W=', w, '\n')
    bandsfile:write('H=', h, '\n')
    bandsfile:write('TransformationMatrix=', tmatrix, '\n')
  end

  bandsfile:flush()
  bandsfile:close()


end

function GetRotationMatrixForBar(angle,x,y,w,h)
  local rx = x + w/2
  local ry = y + h
  return GetRotationMatrix(angle,rx,ry)
end

-- Computes a Transformation matrix, 
-- that transforms the meter by
-- the specified angle around
-- the origin point x,y
function GetRotationMatrix(angle,x,y)

  local radAngle = math.rad(angle)
  local a = math.cos(radAngle)
  local b = math.sin(radAngle)
  local c = -b
  local d = a

  local tx = x - x*a - y*c;
  local ty = y - x*b - y*d;

  return a..';'..b..';'..c..';'..d..';'..tx..';'..ty..';'
end

-- Computes a Transformation matrix, 
-- that transforms the meter by
-- specified angle and scale around
-- the origin point x,y
function GetRotationScaleMatrix(angle,x,y,scale)

  --###################################
  --# TRANSFORMATION MATRIX: ROTATION #
  --###################################
  local radAngle = math.rad(angle)
  local a = math.cos(radAngle)
  local b = math.sin(radAngle)
  local c = -b
  local d = a

  local tx = x - x*a - y*c;
  local ty = y - x*b - y*d;

  -- if the scale is 1, then we just dont have to scale
  if scale ~= 1 then
    --################################
    --# TRANSFORMATION MATRIX: SCALE #
    --################################
    local a2 = scale
    local b2 = 0
    local c2 = 0
    local d2 = scale

    local tx2 = x - x*a2 - y*c2;
    local ty2 = y - x*b2 - y*d2;

    --#########################################
    --# TRANSFORMATION MATRIX: ROTATION+SCALE #
    --#########################################
    local ar = a*a2+c*b2
    local br = b*a2+d*b2
    local cr = a*c2+c*d2
    local dr = b*c2+d*d2

    --man, i hate matrix multiplication :(

    local txr = a*tx2+c*ty2+tx
    local tyr = b*tx2+d*ty2+ty
    return ar..';'..br..';'..cr..';'..dr..';'..txr..';'..tyr..';'
  end
  
  return a..';'..b..';'..c..';'..d..';'..tx..';'..ty..';'
end

function GetGradientOf(color1, color2, percent)
  local gradientcolor = { }

  --print("calculating gradient of "..color1.R..","..color2.R)

  local dr = color2.R - color1.R
  local dg = color2.G - color1.G
  local db = color2.B - color1.B
  local da = color2.A - color1.A

  gradientcolor.R = color1.R + dr * percent * 0.01
  gradientcolor.G = color1.G + dg * percent * 0.01
  gradientcolor.B = color1.B + db * percent * 0.01
  gradientcolor.A = color1.A + da * percent * 0.01

  return gradientcolor
end

function ParseColor(colorstring)
  local color = { }

  if colorstring:sub(0, string.len("#")) == "#" then
    color.R = tonumber(colorstring:sub(2,3),16)
    color.G = tonumber(colorstring:sub(4,5),16)
    color.B = tonumber(colorstring:sub(6,7),16)
    color.A = 255
    color.Percent = tonumber(colorstring:sub(9))
    return color
  end

  --print("i shouldnt print: "..colorstring)

  local carr = split(colorstring, ",")
  color.R = tonumber(carr[1])
  color.G = tonumber(carr[2])
  color.B = tonumber(carr[3])

  local gm = split(carr[4], ":")
  color.A = tonumber(gm[1])
  color.Percent = tonumber(gm[2])

  return color
end

function GetGradients(colorstring, bands)

  local colorarr = { }

  --print(colorstring)

  for key,str in pairs(split(colorstring, "|")) do

    --print(key..": "..str)
    colorarr[key] = ParseColor(str)
    --print(ColorToString(colorarr[key]))
  end

  local colors = table.getn(colorarr)
  local bandcolors = { }

  local iBand = 0
  local iColor = 1
  bands = tonumber(bands)
  local ppb = 100 / bands

  while (iBand < bands) do
    local bandpercent = iBand * ppb
    --print("colorpercent: "..colorarr[iColor].Percent..", bandpercent: "..bandpercent)
    if colorarr[iColor+1].Percent == bandpercent then
      bandcolors[iBand] = colorarr[iColor+1]
      --print("increment color: "..ColorToString(colorarr[iColor]).." to "..ColorToString(colorarr[iColor+1]))
      iColor = iColor + 1
      iBand = iBand + 1
    else 
      if colorarr[iColor+1].Percent > bandpercent then
        local p = ((bandpercent-colorarr[iColor].Percent)/(colorarr[iColor+1].Percent-colorarr[iColor].Percent))*100
        --print("p: "..p)
        bandcolors[iBand] = GetGradientOf(colorarr[iColor],colorarr[iColor+1],p)
        iBand = iBand + 1
      end

      if colorarr[iColor+1].Percent < bandpercent then
        --print("increment color: "..ColorToString(colorarr[iColor]).." to "..ColorToString(colorarr[iColor+1]))
        iColor = iColor + 1
      end
    end

  end
  
  return bandcolors
end

function ColorToString(color)
  return color.R..","..color.G..","..color.B..","..color.A
end

function split(str, d)
  local t={}
  for istr in string.gmatch(str, "([^"..d.."]+)") do
    table.insert(t, istr)
  end
  return t
end