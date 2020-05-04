local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

local function split(str, d)
    local t={}
    for istr in string.gmatch(str, "([^"..d.."]+)") do
        table.insert(t, istr)
    end
    return t
end

SkinFile = {}
function SkinFile.new(skinfile)
    local obj = {}
    obj.skinfilepath = SKIN:ReplaceVariables(skinfile)
    print(obj.skinfilepath)

    function obj:beginGen()
        if (self.file ~= nil) then 
            self.endGen() 
        end
        self.file = io.open(self.skinfilepath, 'w+')
        print(self.file)
    end
    
    function obj:endGen()
        if (self.file == nil) then 
            return nil
        end
        self.file:flush()
        self.file:close()
    end
    
    function obj:readSection(sectionName)
        local bSection = false
        local v = {}
        for line in io.lines(self.skinfilepath) do
            if starts_with(line,'['..sectionName..']') then 
                bSection = true
            elseif line:match('^%[[%w_]+%]') 
            then 
                bSection = false 
            end
            
            if bSection then
                local key, val = line:match('^([%w_]+)%s-=%s-(.-)$')
                v[key or ''] = val
            end
        end
        return v
    end
    
    function obj:genSection(name, options)
        self.file:write('['..name..']\n')
        for key,val in pairs(options) do self.file:write(key..'='..val..'\n') end
    end
    
    function obj:genMeter(name, meterType, measureName, options)
        local reqOptions = {
            Meter       = meterType,
            MeasureName = measureName,
        }
        self:genSection(name, reqOptions)
        for key,val in pairs(options) do self.file:write(key..'='..val..'\n') end
    end
    
    function obj:genMeasure(name, measureType, options)
        local reqOptions = {
            Measure = measureType,
        }
        self:genSection(name, reqOptions)
        for key,val in pairs(options) do self.file:write(key..'='..val..'\n') end
    end
    return obj
end

Color = {}
function Color.Create(r, g, b, a)
    local obj = {}
    obj.R = r or 0
    obj.G = g or 0
    obj.B = b or 0
    obj.A = a or 0

    function obj:Parse(colorstring)
        local o = {}
        self.__index = self
        setmetatable(o, self)
    
        -- #FF0000
        -- #FF0000FF
        if colorstring:sub(0, string.len("#")) == "#" then
            self.R = tonumber(colorstring:sub(2,3),16)
            self.G = tonumber(colorstring:sub(4,5),16)
            self.B = tonumber(colorstring:sub(6,7),16)
            local len = colorstring:len()
            if len >= 9 then
                --if colorstring:sub(8,8) == ':' then
                --    self.GradientPercent = tonumber(colorstring:sub(9),16)
                --else
                    self.A = tonumber(colorstring:sub(8,9),16)
                    --if len > 9 && colorstring:sub(10,10) == ':' then
                    --    self.GradientPercent = tonumber(colorstring:sub(11),16)
                    --end
                --end
            end
            return o
        end
    
        -- 255,0,0
        -- 255,0,0,255
        local carr = split(colorstring, ",")
        self.R = tonumber(carr[1])
        self.G = tonumber(carr[2])
        self.B = tonumber(carr[3])

        if table.getn(carr) == 4 then
            self.A = tonumber(carr[4])
        else
            self.A = 255
        end
    
        --local gm
        --if carr[3]:match(":") then
        --    local gm = split(carr[3], ":")
        --    self.B = tonumber(gm[1])
        --    self.A = 255
        --    self.GradientPercent = tonumber(gm[2])
        --else
        --    local gm = split(carr[4], ":")
        --    self.A = tonumber(gm[1])
        --    self.GradientPercent = tonumber(gm[2])
        --end

        --print(self:ToString())

        return o
    end
    
    function obj:IntermediateOf(color2, percent)
        local dr = color2.R - self.R
        local dg = color2.G - self.G
        local db = color2.B - self.B
        local da = color2.A - self.A
    
        local color = Color.Create(
            self.R + dr * percent * 0.01,
            self.G + dg * percent * 0.01,
            self.B + db * percent * 0.01,
            self.A + da * percent * 0.01
        )
        return color
    end
    
    function obj:ToString()
        a = a or 255
        return self.R..','..self.G..','..self.B..','..self.A --':'..self.GradientPercent
    end

    return obj
end

Gradient = {}
function Gradient.Parse(colorstring)
    local obj = {}

    obj.Percents = {}
    obj.Colors = {}
    for key,str in pairs(split(colorstring, "|")) do
        local s = split(str, ':')
        obj.Percents[key] = tonumber(s[2])
        obj.Colors[key] = Color.Create():Parse(s[1])
    end

    function obj:GetValues(n)
        local colors = table.getn(self.Colors)
        local bandcolors = { }
    
        local iBand = 0
        local iColor = 1
        n = tonumber(n)
        local ppb = 100 / n
        
        while (iBand < n) do
            local bandpercent = iBand * ppb
            --print("colorpercent: "..self.Colors[iColor].Percent..", bandpercent: "..bandpercent)
            if self.Percents[iColor+1] == bandpercent then
            bandcolors[iBand] = self.Colors[iColor+1]
            --print("increment color: "..ColorToString(self.Colors[iColor]).." to "..ColorToString(self.Colors[iColor+1]))
            iColor = iColor + 1
            iBand = iBand + 1
            else 
                if self.Percents[iColor+1] > bandpercent then
                local p = ((bandpercent-self.Percents[iColor])/(self.Percents[iColor+1]-self.Percents[iColor]))*100
                --print("p: "..p)
                bandcolors[iBand] = self.Colors[iColor]:IntermediateOf(self.Colors[iColor+1],p)
                iBand = iBand + 1
                end
    
                if self.Percents[iColor+1] < bandpercent then
                --print("increment color: "..ColorToString(self.Colors[iColor]).." to "..ColorToString(self.Colors[iColor+1]))
                iColor = iColor + 1
                end
            end
        end
        return bandcolors
    end

    function obj:ToString()
        local colors = table.getn(self.Colors)
        local str = self.Colors[1]:ToString()..':'..self.Percents[1]
        for i = 2, colors, 1 do
            str = str..'|'..self.Colors[i]:ToString()..':'..self.Percents[i]
        end
        return str
    end

    return obj
end

TransformationMatrix = {}
function TransformationMatrix.Create(originX, originY)
    local obj = {}

    obj.a = 1
    obj.b = 0
    obj.c = 0
    obj.d = 1
    
    obj.originX = originX
    obj.originY = originY

    obj.tx = originX - originX*obj.a - originY*obj.c;
    obj.ty = originY - originX*obj.b - originY*obj.d;

    -- Computes a Transformation matrix, 
    -- that transforms the meter by
    -- the specified angle around
    -- the origin point x,y
    function obj:Rotate(angle)
        if angle == 0 then return nil end
        local tmatrix = {}
        local radAngle = math.rad(angle)
        tmatrix.a = math.cos(radAngle)
        tmatrix.b = math.sin(radAngle)
        tmatrix.c = -tmatrix.b
        tmatrix.d = tmatrix.a

        tmatrix.tx = self.originX - self.originX*tmatrix.a - self.originY*tmatrix.c;
        tmatrix.ty = self.originY - self.originX*tmatrix.b - self.originY*tmatrix.d;

        self:Merge(tmatrix)
    end
    
    -- Computes a Transformation matrix, 
    -- that transforms the meter by
    -- specified angle and scale around
    -- the origin point x,y
    function obj:Scale(scale)
        if scale == 1 then return nil end
        local tmatrix = {}
        tmatrix.a = scale
        tmatrix.b = 0
        tmatrix.c = 0
        tmatrix.d = scale

        tmatrix.tx = self.originX - self.originX*tmatrix.a - self.originY*tmatrix.c;
        tmatrix.ty = self.originY - self.originX*tmatrix.b - self.originY*tmatrix.d;

        self:Merge(tmatrix)
    end

    function obj:Merge(tmatrix)
        local ar = self.a*tmatrix.a+self.c*tmatrix.b
        local br = self.b*tmatrix.a+self.d*tmatrix.b
        local cr = self.a*tmatrix.c+self.c*tmatrix.d
        local dr = self.b*tmatrix.c+self.d*tmatrix.d

        local txr = self.a*tmatrix.tx+self.c*tmatrix.ty+self.tx
        local tyr = self.b*tmatrix.tx+self.d*tmatrix.ty+self.ty

        self.a = ar
        self.b = br
        self.c = cr
        self.d = dr
        self.tx = txr
        self.ty = tyr
    end

    function obj:ToString()
        return self.a..';'..self.b..';'..self.c..';'..self.d..';'..self.tx..';'..self.ty..';'
    end
    return obj
end

