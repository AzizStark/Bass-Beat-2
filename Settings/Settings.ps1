Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Import custom Windows.Forms Controls
. ./PSForms.ps1

$wppsdef = @'
[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool WritePrivateProfileString(string lpAppName,
   string lpKeyName,
   string lpString,
   string lpFileName);
'@

$wpps = Add-Type -MemberDefinition $wppsdef -Name WinWritePrivateProfileString -Namespace Win32Utils -PassThru

$v = @{}
$variablesPath = Resolve-Path "..\@Resources\Variables.inc"
$raw = Get-Content -Path $variablesPath
foreach ($line in $raw)
{
    if ($line -match "^(\w+)\s??=\s??(.*?);?\n?$")
    {
        Write-Host $matches[1]:  $matches[2]
        $v[$matches[1]] = $matches[2]
    }
}

$rmPath = (Get-Process "Rainmeter").Path

function ToRMColor([System.Drawing.Color] $color)
{
    $colorR = [int]$color.R
    $colorG = [int]$color.G
    $colorB = [int]$color.B
    $colorA = [int]$color.A
    return "$colorR,$colorG,$colorB,$colorA"
}

function ToSDColor([string] $color)
{
    $colors = $color.Split(',')
    if ($colors.Count -lt 4)
    {
        $colors = @(255,255,255,255)
    }
    return [System.Drawing.Color]::FromArgb($colors[3], $colors[0], $colors[1], $colors[2])
}

function ToRMGradient([System.Drawing.Drawing2D.ColorBlend] $gradient)
{
    $rmgradient = ""

    for ($i = 0; $i -lt $gradient.Colors.Count; $i++)
    {
        $rmcolor = ToRMColor $gradient.Colors[$i]
        $rmgradient += $rmcolor + ":" + [math]::Round($gradient.Positions[$i]*100) + "|"
    }

    # remove trailing "|"
    $rmgradient = $rmgradient.Substring(0, $rmgradient.Length-1)
    return $rmgradient
}

$form                            = New-Object system.Windows.Forms.Form
$form.ClientSize                 = '790,440'
$form.text                       = $v["Config"]
$form.TopMost                    = $false
$form.Icon                       = [Drawing.Icon]::ExtractAssociatedIcon($rmPath)
$form.AutoSize                   = $false
$form.FormBorderStyle            = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.ShowInTaskbar              = $false
$form.MinimizeBox                = $false
$form.MaximizeBox                = $false

$gbGeneral                       = New-Object system.Windows.Forms.Groupbox
$gbGeneral.height                = 140
$gbGeneral.width                 = 250
$gbGeneral.text                  = "General"
$gbGeneral.location              = New-Object System.Drawing.Point(10,10)

$gbBar                           = New-Object system.Windows.Forms.Groupbox
$gbBar.height                    = 140
$gbBar.width                     = 250
$gbBar.text                      = "Bar"
$gbBar.location                  = New-Object System.Drawing.Point(10,160)

$numRadius                       = New-Object System.Windows.Forms.NumericUpDown
$numRadius.width                 = 100
$numRadius.height                = 20
$numRadius.location              = New-Object System.Drawing.Point(140,15)
$numRadius.Font                  = 'Microsoft Sans Serif,8'
$numRadius.Minimum               = 0
$numRadius.Maximum               = 1000
$numRadius.Value                 = $v["Radius"]

$lblRadius                       = New-Object system.Windows.Forms.Label
$lblRadius.text                  = "Radius"
$lblRadius.AutoSize              = $true
$lblRadius.width                 = 25
$lblRadius.height                = 10
$lblRadius.location              = New-Object System.Drawing.Point(10,20)
$lblRadius.Font                  = 'Microsoft Sans Serif,8'

$lblStartAngle                   = New-Object system.Windows.Forms.Label
$lblStartAngle.text              = "Start angle"
$lblStartAngle.AutoSize          = $true
$lblStartAngle.width             = 25
$lblStartAngle.height            = 10
$lblStartAngle.location          = New-Object System.Drawing.Point(10,50)
$lblStartAngle.Font              = 'Microsoft Sans Serif,8'

$lblEndAngle                     = New-Object system.Windows.Forms.Label
$lblEndAngle.text                = "End angle"
$lblEndAngle.AutoSize            = $true
$lblEndAngle.width               = 25
$lblEndAngle.height              = 10
$lblEndAngle.location            = New-Object System.Drawing.Point(10,80)
$lblEndAngle.Font                = 'Microsoft Sans Serif,8'

$lblBarAmount                    = New-Object system.Windows.Forms.Label
$lblBarAmount.text               = "Bar amount"
$lblBarAmount.AutoSize           = $true
$lblBarAmount.width              = 25
$lblBarAmount.height             = 10
$lblBarAmount.location           = New-Object System.Drawing.Point(9,20)
$lblBarAmount.Font               = 'Microsoft Sans Serif,8'

$lblBarColor                     = New-Object system.Windows.Forms.Label
$lblBarColor.text                = "Reserved [WIP]"
$lblBarColor.AutoSize            = $true
$lblBarColor.width               = 25
$lblBarColor.height              = 10
$lblBarColor.location            = New-Object System.Drawing.Point(10,50)
$lblBarColor.Font                = 'Microsoft Sans Serif,8'
$lblBarColor.Enabled             = $false

$lblBarWidth                     = New-Object system.Windows.Forms.Label
$lblBarWidth.text                = "Bar width"
$lblBarWidth.AutoSize            = $true
$lblBarWidth.width               = 25
$lblBarWidth.height              = 10
$lblBarWidth.location            = New-Object System.Drawing.Point(10,80)
$lblBarWidth.Font                = 'Microsoft Sans Serif,8'

$lblBarHeight                    = New-Object system.Windows.Forms.Label
$lblBarHeight.text               = "Bar height"
$lblBarHeight.AutoSize           = $true
$lblBarHeight.width              = 25
$lblBarHeight.height             = 10
$lblBarHeight.location           = New-Object System.Drawing.Point(10,110)
$lblBarHeight.Font               = 'Microsoft Sans Serif,8'

$gbSmoothing                     = New-Object system.Windows.Forms.Groupbox
$gbSmoothing.height              = 80
$gbSmoothing.width               = 250
$gbSmoothing.text                = "Smoothing"
$gbSmoothing.location            = New-Object System.Drawing.Point(270,10)

$gbVisualization                 = New-Object system.Windows.Forms.Groupbox
$gbVisualization.height          = 170
$gbVisualization.width           = 250
$gbVisualization.text            = "Visualization"
$gbVisualization.location        = New-Object System.Drawing.Point(270,100)

$gbMirror                        = New-Object system.Windows.Forms.Groupbox
$gbMirror.height                 = 80
$gbMirror.width                  = 250
$gbMirror.text                   = "Mirror"
$gbMirror.location               = New-Object System.Drawing.Point(10,310)

$lblSmoothing                    = New-Object system.Windows.Forms.Label
$lblSmoothing.text               = "Smoothing"
$lblSmoothing.AutoSize           = $true
$lblSmoothing.width              = 25
$lblSmoothing.height             = 10
$lblSmoothing.location           = New-Object System.Drawing.Point(10,20)
$lblSmoothing.Font               = 'Microsoft Sans Serif,8'

$lblPastValueAveraging           = New-Object system.Windows.Forms.Label
$lblPastValueAveraging.text      = "Past value averaging"
$lblPastValueAveraging.AutoSize  = $true
$lblPastValueAveraging.width     = 25
$lblPastValueAveraging.height    = 10
$lblPastValueAveraging.location  = New-Object System.Drawing.Point(10,50)
$lblPastValueAveraging.Font      = 'Microsoft Sans Serif,8'

$lblFFTSize                      = New-Object system.Windows.Forms.Label
$lblFFTSize.text                 = "FFTSize"
$lblFFTSize.AutoSize             = $true
$lblFFTSize.width                = 25
$lblFFTSize.height               = 10
$lblFFTSize.location             = New-Object System.Drawing.Point(10,20)
$lblFFTSize.Font                 = 'Microsoft Sans Serif,8'

$lblFFTBufferSize                = New-Object system.Windows.Forms.Label
$lblFFTBufferSize.text           = "FFTBufferSize"
$lblFFTBufferSize.AutoSize       = $true
$lblFFTBufferSize.width          = 25
$lblFFTBufferSize.height         = 10
$lblFFTBufferSize.location       = New-Object System.Drawing.Point(10,50)
$lblFFTBufferSize.Font           = 'Microsoft Sans Serif,8'

$lblFFTAttack                    = New-Object system.Windows.Forms.Label
$lblFFTAttack.text               = "Attack"
$lblFFTAttack.AutoSize           = $true
$lblFFTAttack.width              = 25
$lblFFTAttack.height             = 10
$lblFFTAttack.location           = New-Object System.Drawing.Point(10,80)
$lblFFTAttack.Font               = 'Microsoft Sans Serif,8'

$lblFFTDecay                     = New-Object system.Windows.Forms.Label
$lblFFTDecay.text                = "Decay"
$lblFFTDecay.AutoSize            = $true
$lblFFTDecay.width               = 25
$lblFFTDecay.height              = 10
$lblFFTDecay.location            = New-Object System.Drawing.Point(10,110)
$lblFFTDecay.Font                = 'Microsoft Sans Serif,8'

$cbMirror                        = New-Object system.Windows.Forms.CheckBox
$cbMirror.text                   = "Mirror"
$cbMirror.AutoSize               = $false
$cbMirror.width                  = 95
$cbMirror.height                 = 20
$cbMirror.location               = New-Object System.Drawing.Point(10,20)
$cbMirror.Font                   = 'Microsoft Sans Serif,8'
$cbMirror.Checked                = [int]$v["Mirror"]

$cbInvertMirror                  = New-Object system.Windows.Forms.CheckBox
$cbInvertMirror.text             = "Invert Mirror"
$cbInvertMirror.AutoSize         = $false
$cbInvertMirror.width            = 95
$cbInvertMirror.height           = 20
$cbInvertMirror.location         = New-Object System.Drawing.Point(10,50)
$cbInvertMirror.Font             = 'Microsoft Sans Serif,8'
$cbInvertMirror.Checked          = [int]$v["InvertMirror"]
$cbInvertMirror.Enabled          = [int]$v["Mirror"]

$gbFrequency                     = New-Object system.Windows.Forms.Groupbox
$gbFrequency.height              = 110
$gbFrequency.width               = 250
$gbFrequency.text                = "Freqency"
$gbFrequency.location            = New-Object System.Drawing.Point(270,280)

$lblStartFreqency                = New-Object system.Windows.Forms.Label
$lblStartFreqency.text           = "Start Freqency"
$lblStartFreqency.AutoSize       = $true
$lblStartFreqency.width          = 25
$lblStartFreqency.height         = 10
$lblStartFreqency.location       = New-Object System.Drawing.Point(10,50)
$lblStartFreqency.Font           = 'Microsoft Sans Serif,8'

$lblEndFreqency                  = New-Object system.Windows.Forms.Label
$lblEndFreqency.text             = "End Freqency"
$lblEndFreqency.AutoSize         = $true
$lblEndFreqency.width            = 25
$lblEndFreqency.height           = 10
$lblEndFreqency.location         = New-Object System.Drawing.Point(10,80)
$lblEndFreqency.Font             = 'Microsoft Sans Serif,8'

$lblAngularDisplacement          = New-Object system.Windows.Forms.Label
$lblAngularDisplacement.text     = "Angle displacement"
$lblAngularDisplacement.AutoSize = $true
$lblAngularDisplacement.width    = 25
$lblAngularDisplacement.height   = 10
$lblAngularDisplacement.location = New-Object System.Drawing.Point(10,110)
$lblAngularDisplacement.Font     = 'Microsoft Sans Serif,8'

$lblPresets                      = New-Object system.Windows.Forms.Label
$lblPresets.text                 = "Presets"
$lblPresets.AutoSize             = $true
$lblPresets.width                = 25
$lblPresets.height               = 10
$lblPresets.location             = New-Object System.Drawing.Point(10,20)
$lblPresets.Font                 = 'Microsoft Sans Serif,8'

$lblSensitivity                  = New-Object system.Windows.Forms.Label
$lblSensitivity.text             = "Sensitivity"
$lblSensitivity.AutoSize         = $true
$lblSensitivity.width            = 25
$lblSensitivity.height           = 10
$lblSensitivity.location         = New-Object System.Drawing.Point(10,140)
$lblSensitivity.Font             = 'Microsoft Sans Serif,8'

$numStartAngle                   = New-Object System.Windows.Forms.NumericUpDown
$numStartAngle.width             = 100
$numStartAngle.height            = 20
$numStartAngle.location          = New-Object System.Drawing.Point(140,45)
$numStartAngle.Font              = 'Microsoft Sans Serif,8'
$numStartAngle.Minimum           = 0
$numStartAngle.Maximum           = 360
$numStartAngle.Value             = $v["StartAngle"]

$numEndAngle                     = New-Object system.Windows.Forms.NumericUpDown
$numEndAngle.width               = 100
$numEndAngle.height              = 20
$numEndAngle.location            = New-Object System.Drawing.Point(140,75)
$numEndAngle.Font                = 'Microsoft Sans Serif,8'
$numEndAngle.Minimum             = 0
$numEndAngle.Maximum             = 360
$numEndAngle.Value               = $v["EndAngle"]

$numAngularDisplacement          = New-Object system.Windows.Forms.NumericUpDown
$numAngularDisplacement.width    = 100
$numAngularDisplacement.height   = 20
$numAngularDisplacement.location  = New-Object System.Drawing.Point(140,105)
$numAngularDisplacement.Font     = 'Microsoft Sans Serif,8'
$numAngularDisplacement.Minimum  = 0
$numAngularDisplacement.Maximum  = 360
$numAngularDisplacement.Value    = $v["AngularDisplacement"]

$numBars                         = New-Object system.Windows.Forms.NumericUpDown
$numBars.width                   = 100
$numBars.height                  = 20
$numBars.location                = New-Object System.Drawing.Point(140,15)
$numBars.Font                    = 'Microsoft Sans Serif,8'
$numBars.Minimum                 = 0
$numBars.Maximum                 = 2000
$numBars.Value                   = $v["Bands"]

$numBarWidth                     = New-Object system.Windows.Forms.NumericUpDown
$numBarWidth.width               = 100
$numBarWidth.height              = 20
$numBarWidth.location            = New-Object System.Drawing.Point(140,75)
$numBarWidth.Font                = 'Microsoft Sans Serif,8'
$numBarWidth.Minimum             = 1
$numBarWidth.Maximum             = 100
$numBarWidth.Value               = $v["BarWidth"]

$numBarHeight                    = New-Object system.Windows.Forms.NumericUpDown
$numBarHeight.width              = 100
$numBarHeight.height             = 20
$numBarHeight.location           = New-Object System.Drawing.Point(140,105)
$numBarHeight.Font               = 'Microsoft Sans Serif,8'
$numBarHeight.Minimum            = 1
$numBarHeight.Maximum            = 1000
$numBarHeight.Value              = $v["BarHeight"]

$numFFTAttack                    = New-Object system.Windows.Forms.NumericUpDown
$numFFTAttack.width              = 100
$numFFTAttack.height             = 20
$numFFTAttack.location           = New-Object System.Drawing.Point(140,75)
$numFFTAttack.Font               = 'Microsoft Sans Serif,8'
$numFFTAttack.Minimum            = 0
$numFFTAttack.Maximum            = 1000
$numFFTAttack.Value              = $v["FFTAttack"]

$numFFTDecay                     = New-Object system.Windows.Forms.NumericUpDown
$numFFTDecay.width               = 100
$numFFTDecay.height              = 20
$numFFTDecay.location            = New-Object System.Drawing.Point(140,105)
$numFFTDecay.Font                = 'Microsoft Sans Serif,8'
$numFFTDecay.Minimum             = 0
$numFFTDecay.Maximum             = 1000
$numFFTDecay.Value               = $v["FFTDecay"]

$cbFFTSize                       = New-Object System.Windows.Forms.ComboBox
$cbFFTSize.width                 = 100
$cbFFTSize.height                = 20
$cbFFTSize.location              = New-Object System.Drawing.Point(140,15)
$cbFFTSize.Font                  = 'Microsoft Sans Serif,8'
$cbFFTSize.DropDownStyle         = 'DropDownList'
$cbFFTSize.Items.AddRange(@(512,1024,2048,4096,8192))
$cbFFTSize.SelectedIndex         = [Math]::Round([Math]::Log($v["FFTSize"], 2)-9)

$cbFFTBufferSize                 = New-Object System.Windows.Forms.ComboBox
$cbFFTBufferSize.width           = 100
$cbFFTBufferSize.height          = 20
$cbFFTBufferSize.location        = New-Object System.Drawing.Point(140,45)
$cbFFTBufferSize.Font            = 'Microsoft Sans Serif,8'
$cbFFTBufferSize.DropDownStyle   = 'DropDownList'
$cbFFTBufferSize.Items.AddRange(@(4096,8192,16384,32768))
$cbFFTBufferSize.SelectedIndex   = [Math]::Round([Math]::Log($v["FFTBufferSize"], 2)-12)


$numSensitivity                  = New-Object system.Windows.Forms.NumericUpDown
$numSensitivity.width            = 100
$numSensitivity.height           = 20
$numSensitivity.location         = New-Object System.Drawing.Point(140,135)
$numSensitivity.Font             = 'Microsoft Sans Serif,8'
$numSensitivity.Minimum          = 0
$numSensitivity.Maximum          = 100
$numSensitivity.Value            = $v["Sensitivity"]

$numFreqMin                      = New-Object system.Windows.Forms.NumericUpDown
$numFreqMin.width                = 100
$numFreqMin.height               = 20
$numFreqMin.location             = New-Object System.Drawing.Point(140,45)
$numFreqMin.Font                 = 'Microsoft Sans Serif,8'
$numFreqMin.Minimum              = 20
$numFreqMin.Maximum              = 20000
$numFreqMin.Value                = $v["FreqMin"]

$numFreqMax                      = New-Object system.Windows.Forms.NumericUpDown
$numFreqMax.width                = 100
$numFreqMax.height               = 20
$numFreqMax.location             = New-Object System.Drawing.Point(140,75)
$numFreqMax.Font                 = 'Microsoft Sans Serif,8'
$numFreqMax.Minimum              = 20
$numFreqMax.Maximum              = 20000
$numFreqMax.Value                = $v["FreqMax"]

$numSmoothing                    = New-Object system.Windows.Forms.NumericUpDown
$numSmoothing.width              = 100
$numSmoothing.height             = 20
$numSmoothing.location           = New-Object System.Drawing.Point(140,15)
$numSmoothing.Font               = 'Microsoft Sans Serif,8'
$numSmoothing.Minimum            = 0
$numSmoothing.Maximum            = 10
$numSmoothing.Value              = $v["Smoothing"]

$numPastValueAvg                 = New-Object system.Windows.Forms.NumericUpDown
$numPastValueAvg.width           = 100
$numPastValueAvg.height          = 20
$numPastValueAvg.location        = New-Object System.Drawing.Point(140,45)
$numPastValueAvg.Font            = 'Microsoft Sans Serif,8'
$numPastValueAvg.Minimum         = 1
$numPastValueAvg.Maximum         = 10
$numPastValueAvg.Value           = $v["AveragingPastValuesAmount"]

$gbSpecial                       = New-Object system.Windows.Forms.Groupbox
$gbSpecial.height                = 190
$gbSpecial.width                 = 250
$gbSpecial.text                  = "Special"
$gbSpecial.location              = New-Object System.Drawing.Point(530,200)

$cbInvertBars                    = New-Object system.Windows.Forms.CheckBox
$cbInvertBars.text               = "Flip Bars"
$cbInvertBars.AutoSize           = $false
$cbInvertBars.width              = 95
$cbInvertBars.height             = 20
$cbInvertBars.location           = New-Object System.Drawing.Point(10,20)
$cbInvertBars.Font               = 'Microsoft Sans Serif,8'
$cbInvertBars.Checked            = [int]$v["InvertBars"]

$lblFeatures                     = New-Object system.Windows.Forms.LinkLabel
$lblFeatures.text                = "Too much space for new features!" + [System.Environment]::NewLine + "Request new features at deviantart.com/SnGmng/BeatCircle"
$lblFeatures.AutoSize            = $false
$lblFeatures.width               = 210
$lblFeatures.height              = 40
$lblFeatures.location            = New-Object System.Drawing.Point(20,85)
$lblFeatures.Font                = 'Microsoft Sans Serif,8'
$lblFeatures.TextAlign           = [System.Drawing.ContentAlignment]::MiddleCenter

$gbColor                         = New-Object system.Windows.Forms.Groupbox
$gbColor.height                  = 180
$gbColor.width                   = 250
$gbColor.text                    = "Color"
$gbColor.location                = New-Object System.Drawing.Point(530,10)

$colorgradctr                    = New-Object PSForms.ColorGradientControl
$colorgradctr.Width              = 210
$colorgradctr.Height             = 50
$colorgradctr.location           = New-Object System.Drawing.Point(20,110)

$gradcolors = $v["GColor"].Split('|')
if ($gradcolors.Count -lt 2)
{
    $color = ToSDColor $v["SColor"]
    $colorgradctr.reset($color,$color)
}
else
{
    $gradcolor1 = $gradcolors[0].Split(':')
    $color1 = ToSDColor $gradcolor1[0]
    $gradcolor2 = $gradcolors[$gradcolors.Count-1].Split(':')
    $color2 = ToSDColor $gradcolor2[0]

    $colorgradctr.reset($color1,$color2)

    for ($i = 1; $i -lt $gradcolors.Count-1; $i++)
    {
        $gradcolor = $gradcolors[$i].Split(':')
        $color = ToSDColor $gradcolor[0]
        $position = $gradcolor[1]/100
        $colorgradctr.addColor($color, $position)
    }
}

$pnlBarColor                     = New-Object system.Windows.Forms.Panel
$pnlBarColor.height              = 30
$pnlBarColor.width               = 210
$pnlBarColor.location            = New-Object System.Drawing.Point(20,45)
$pnlBarColor.BorderStyle         = 2
$pnlBarColor.BackColor           = ToSDColor $v["SColor"]

$rbSolidColor                    = New-Object System.Windows.Forms.RadioButton
$rbSolidColor.AutoSize           = $true
$rbSolidColor.location           = New-Object System.Drawing.Point(10,20)
$rbSolidColor.Text               = "Single Color"

$rbGradientColor                 = New-Object System.Windows.Forms.RadioButton
$rbGradientColor.AutoSize        = $true
$rbGradientColor.location        = New-Object System.Drawing.Point(10,80)
$rbGradientColor.Text            = "Gradient Color"
$rbGradientColor.Checked         = [int]$v["Gradient"]
$rbSolidColor.Checked = !$rbGradientColor.Checked


$dummy = $lblFeatures.Links.Add(58,32)
$lblFeatures.Add_LinkClicked({ featuresLinkClicked })
###########
# BUTTONS #
###########

$btnApply                        = New-Object system.Windows.Forms.Button
$btnApply.text                   = "Apply"
$btnApply.width                  = 770
$btnApply.height                 = 30
$btnApply.location               = New-Object System.Drawing.Point(10,400)
$btnApply.Font                   = 'Microsoft Sans Serif,10'

$btnLows                         = New-Object system.Windows.Forms.Button
$btnLows.text                    = "Lows"
$btnLows.width                   = 50
$btnLows.height                  = 20
$btnLows.location                = New-Object System.Drawing.Point(70,13)
$btnLows.Font                    = 'Microsoft Sans Serif,8'

$btnMids                         = New-Object system.Windows.Forms.Button
$btnMids.text                    = "Mids"
$btnMids.width                   = 50
$btnMids.height                  = 20
$btnMids.location                = New-Object System.Drawing.Point(130,13)
$btnMids.Font                    = 'Microsoft Sans Serif,8'

$btnAll                          = New-Object system.Windows.Forms.Button
$btnAll.text                     = "All"
$btnAll.width                    = 50
$btnAll.height                   = 20
$btnAll.location                 = New-Object System.Drawing.Point(190,13)
$btnAll.Font                     = 'Microsoft Sans Serif,8'

$colorPicker                     = New-Object System.Windows.Forms.ColorDialog
$colorPicker.AllowFullOpen       = $true
$colorPicker.AnyColor            = $true
$colorPicker.FullOpen            = $true
$colorPicker.ShowHelp            = $true

$btnApply.Add_Click({ applyClick })
$btnLows.Add_Click({ btnLowsClick })
$btnMids.Add_Click({ btnMidsClick })
$btnAll.Add_Click({ btnAllClick })
$pnlBarColor.Add_Click({ barcolorClick })
$cbMirror.Add_CheckedChanged({ cbMirrorChecked })

function WriteKeyValue([string] $key, [string] $value)
{
    $wpps::WritePrivateProfileString("Variables", $key, $value, $variablesPath)
}

function WriteKeyValueRM([string] $key, [string] $value)
{
    & $rmPath !WriteKeyValue Variables $key $value "$variablesPath"
}

function DeleteKey([string] $key)
{
    $wpps::WritePrivateProfileString("Variables", $key, [NullString]::Value, $variablesPath)
}

function CommandMeasure([string] $measure, [string] $arguments, [string] $config)
{
    & $rmPath !CommandMeasure "$measure" "$arguments" "$config"
}

function cbMirrorChecked 
{
    $cbInvertMirror.Enabled = $cbMirror.Checked
}

function featuresLinkClicked
{
    [System.Diagnostics.Process]::Start("https://www.deviantart.com/sngmng/art/BeatCircle-Visualizer-v1-0-3-801312023");
}

function btnLowsClick 
{
    $numFreqMin.Value = 25;
    $numFreqMax.Value = 200;
}

function btnMidsClick 
{
    $numFreqMin.Value = 25;
    $numFreqMax.Value = 2000;
}

function btnAllClick
{
    $numFreqMin.Value = 20;
    $numFreqMax.Value = 15000;
}

function applyClick 
{
    $colorblend = $colorgradctr.getColorBlend()

    $solidColor = ToRMColor $pnlBarColor.BackColor
    $gradientColor = ToRMGradient $colorblend

    Write-Host $gradientColor

    $doGradient = [int]$rbGradientColor.Checked
    $doMirror = [int]$cbMirror.Checked
    $doInvertMirror = [int]$cbInvertMirror.Checked
    $doFlipBars = [int]$cbInvertBars.Checked
    $fftSize = [Math]::Pow(2, 9 + $cbFFTSize.SelectedIndex)
    $fftBufferSize = [Math]::Pow(2, 12 + $cbFFTBufferSize.SelectedIndex)

    if ($fftBufferSize -lt $fftSize)
    {
        $fftBufferSize = $fftSize
        $cbFFTBufferSize.SelectedIndex = [Math]::Round([Math]::Log($fftSize, 2)-12)
    }


    WriteKeyValue Bands $numBars.Value
    WriteKeyValue BarWidth $numBarWidth.Value
    WriteKeyValue BarHeight $numBarHeight.Value
    WriteKeyValue Radius $numRadius.Value
    WriteKeyValue StartAngle $numStartAngle.Value
    WriteKeyValue EndAngle $numEndAngle.Value
    WriteKeyValue AngularDisplacement $numAngularDisplacement.Value
    WriteKeyValue Smoothing $numSmoothing.Value
    WriteKeyValue AveragingPastValuesAmount $numPastValueAvg.Value

    WriteKeyValue Gradient $doGradient
    WriteKeyValue SColor $solidColor
    WriteKeyValue GColor $gradientColor

    WriteKeyValue Mirror $doMirror
    WriteKeyValue InvertMirror $doInvertMirror
    WriteKeyValue InvertBars $doFlipBars

    WriteKeyValue FFTSize $fftSize
    WriteKeyValue FFTBufferSize $fftBufferSize
    WriteKeyValue FFTAttack $numFFTAttack.Value
    WriteKeyValue FFTDecay $numFFTDecay.Value
    WriteKeyValue FreqMin $numFreqMin.Value
    WriteKeyValue FreqMax $numFreqMax.Value
    WriteKeyValue Sensitivity $numSensitivity.Value

    CommandMeasure "InitScript" "GenerateHOC()" $v["Config"]
}

function barcolorClick 
{
    if ($colorPicker.ShowDialog() -eq 1)
    {
        $pnlBarColor.BackColor = $colorPicker.Color
    }
}


$form.controls.AddRange(@($gbGeneral,$gbBar,$gbSmoothing,$gbVisualization,$gbMirror,$gbFrequency,$gbColor,$gbSpecial,$btnApply))
$gbGeneral.controls.AddRange(@($numRadius,$lblRadius,$lblStartAngle,$lblEndAngle,$lblAngularDisplacement,$numStartAngle,$numEndAngle,$numAngularDisplacement))
$gbBar.controls.AddRange(@($lblBarAmount,$lblBarColor,$lblBarWidth,$lblBarHeight,$numBars,$numBarWidth,$numBarHeight))
$gbSmoothing.controls.AddRange(@($lblSmoothing,$lblPastValueAveraging,$numSmoothing,$numPastValueAvg))
$gbVisualization.controls.AddRange(@($lblFFTSize,$lblFFTBufferSize,$lblFFTAttack,$lblFFTDecay,$lblSensitivity,$numFFTAttack,$numFFTDecay,$cbFFTBufferSize,$cbFFTSize,$numSensitivity))
$gbMirror.controls.AddRange(@($cbMirror,$cbInvertMirror))
$gbFrequency.controls.AddRange(@($lblStartFreqency,$lblEndFreqency,$lblPresets,$numFreqMin,$numFreqMax,$btnLows,$btnMids,$btnAll))
$gbSpecial.controls.AddRange(@($cbInvertBars, $lblFeatures, $colorgradctr))
$gbColor.controls.AddRange(@($rbSolidColor,$rbGradientColor, $colorgradctr, $pnlBarColor))


$form.ResumeLayout()

[Windows.Forms.Application]::Run($form)