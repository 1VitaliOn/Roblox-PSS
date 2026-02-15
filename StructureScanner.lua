-- ===================================================
-- PLUGIN: Structure Scanner for AI (Simple Version)
-- ===================================================

-- 1. CREATE TOOLBAR BUTTON
local toolbar = plugin:CreateToolbar("Structure Scanner")
local button = toolbar:CreateButton(
	"OpenScanner",
	"Open project structure window",
	"rbxassetid://4483359991",
	"Scans project and outputs structure for AI"
)

-- 2. CREATE WINDOW
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	true,
	false,
	500,
	400,
	300,
	250
)

local widget = plugin:CreateDockWidgetPluginGui("StructureScannerWidget", widgetInfo)
widget.Title = "Project Structure Scanner"

-- 3. CREATE UI
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.Parent = widget

-- Text box (read-only)
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 1, -50)
textBox.Position = UDim2.new(0, 10, 0, 10)
textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
textBox.Text = "Click 'Scan Project' to get structure..."
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.ClearTextOnFocus = false
textBox.TextWrapped = true
textBox.Font = Enum.Font.Code
textBox.TextSize = 13
textBox.MultiLine = true
textBox.Parent = mainFrame

-- Scan button
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(1, -20, 0, 30)
scanButton.Position = UDim2.new(0, 10, 1, -40)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "Scan Project"
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 16
scanButton.Parent = mainFrame

-- 4. SCANNING FUNCTION (with nice output)
local function getProjectStructure()
	local rootServices = {
		game:GetService("Workspace"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"),
		game:GetService("StarterGui"),
		game:GetService("StarterPack"),
		game:GetService("Lighting"),
		game:GetService("SoundService")
	}
	
	local resultLines = {"Game"}
	
	-- Function to get readable class name
	local function getFriendlyClassName(obj)
		local className = obj.ClassName
		local friendlyNames = {
			BasePart = "Part",
			MeshPart = "Mesh",
			WedgePart = "Wedge",
			CylinderPart = "Cylinder",
			BallPart = "Ball",
			ModuleScript = "Module",
			LocalScript = "Local"
		}
		return friendlyNames[className] or className
	end
	
	-- Recursive function to build tree
	local function scanObject(obj, level, isLast, prefix)
		prefix = prefix or ""
		
		local line = ""
		
		if level > 0 then
			if isLast then
				line = prefix .. "└── "
				prefix = prefix .. "    "
			else
				line = prefix .. "├── "
				prefix = prefix .. "│   "
			end
		end
		
		local objName = obj.Name
		local objType = getFriendlyClassName(obj)
		line = line .. objName .. " (" .. objType .. ")"
		
		table.insert(resultLines, line)
		
		local children = obj:GetChildren()
		if #children > 0 then
			-- Sort: folders and models first
			table.sort(children, function(a, b)
				local aIsContainer = a:IsA("Folder") or a:IsA("Model")
				local bIsContainer = b:IsA("Folder") or b:IsA("Model")
				if aIsContainer ~= bIsContainer then
					return aIsContainer
				end
				return a.Name < b.Name
			end)
			
			for i, child in ipairs(children) do
				if child.Name:sub(1, 1) ~= "_" then
					scanObject(child, level + 1, i == #children, prefix)
				end
			end
		end
	end
	
	-- Scan each service
	for i, service in ipairs(rootServices) do
		if service then
			scanObject(service, 1, i == #rootServices, "")
		end
	end
	
	return table.concat(resultLines, "\n")
end

-- 5. CONNECT SCAN BUTTON
scanButton.MouseButton1Click:Connect(function()
	local structure = getProjectStructure()
	textBox.Text = structure
	-- Reset cursor to beginning
	textBox.CursorPosition = -1
end)

-- 6. WINDOW VISIBILITY CONTROL
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

plugin.Unloading:Connect(function()
	button:Destroy()
	widget:Destroy()
end)

print("✅ Structure Scanner loaded! Click the scanner icon.")