-- ===================================================
-- ПЛАГИН: Structure Scanner for AI (С РАБОЧИМ КОПИРОВАНИЕМ)
-- ===================================================

-- 1. ПОДКЛЮЧАЕМ НЕОБХОДИМЫЕ СЕРВИСЫ
local Selection = game:GetService("Selection")

-- ===================================================
-- 2. СОЗДАЕМ КНОПКУ НА ПАНЕЛИ (TOOLBAR)
-- ===================================================
local toolbar = plugin:CreateToolbar("Structure Scanner")
local button = toolbar:CreateButton(
	"OpenScanner",
	"Открыть окно структуры",
	"rbxassetid://4483359991",
	"Сканирует проект и выводит структуру для ИИ"
)

-- ===================================================
-- 3. СОЗДАЕМ ОКНО (DockWidgetPluginGui)
-- ===================================================
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	true,
	false,
	500,   -- Ширина окна
	450,   -- Высота окна (чуть больше для подсказки)
	300,
	250
)

local widget = plugin:CreateDockWidgetPluginGui("StructureScannerWidget", widgetInfo)
widget.Title = "Project Structure Scanner"

-- ===================================================
-- 4. СОЗДАЕМ ЭЛЕМЕНТЫ ИНТЕРФЕЙСА
-- ===================================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.Parent = widget

-- Текстовое поле
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 1, -90) -- Больше места для подсказки снизу
textBox.Position = UDim2.new(0, 10, 0, 10)
textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
textBox.Text = "Нажми 'Scan Project' для получения структуры..."
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.ClearTextOnFocus = false
textBox.TextWrapped = true
textBox.Font = Enum.Font.Code
textBox.TextSize = 13
textBox.MultiLine = true
textBox.Parent = mainFrame

-- Кнопка "Scan Project"
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0.33, -10, 0, 30)
scanButton.Position = UDim2.new(0, 10, 1, -70)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "Scan Project"
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 14
scanButton.Parent = mainFrame

-- Кнопка "Copy" (просто выделяет текст)
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0.33, -10, 0, 30)
copyButton.Position = UDim2.new(0.33, 10, 1, -70)
copyButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Оранжевый
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Text = "Выделить текст"
copyButton.Font = Enum.Font.GothamBold
copyButton.TextSize = 14
copyButton.Parent = mainFrame

-- Кнопка "Copy to Clipboard" с понятной инструкцией
local copyInstructionsBtn = Instance.new("TextButton")
copyInstructionsBtn.Size = UDim2.new(0.33, -10, 0, 30)
copyInstructionsBtn.Position = UDim2.new(0.66, 10, 1, -70)
copyInstructionsBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
copyInstructionsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyInstructionsBtn.Text = "❓ Как копировать"
copyInstructionsBtn.Font = Enum.Font.GothamBold
copyInstructionsBtn.TextSize = 14
copyInstructionsBtn.Parent = mainFrame

-- Текстовая подсказка снизу
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -20, 0, 20)
hintLabel.Position = UDim2.new(0, 10, 1, -30)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
hintLabel.Text = "👉 Выдели текст и нажми Ctrl+C (Cmd+C на Mac) чтобы скопировать"
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 12
hintLabel.TextXAlignment = Enum.TextXAlignment.Center
hintLabel.Parent = mainFrame

-- ===================================================
-- 5. УЛУЧШЕННАЯ ЛОГИКА СКАНИРОВАНИЯ
-- ===================================================
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
	
	-- Функция для получения красивого имени класса
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
	
	-- Рекурсивная функция для построения дерева
	local function scanObject(obj, level, isLast, prefix)
		prefix = prefix or ""
		
		local currentPrefix = prefix
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
	
	for i, service in ipairs(rootServices) do
		if service then
			scanObject(service, 1, i == #rootServices, "")
		end
	end
	
	return table.concat(resultLines, "\n")
end

-- ===================================================
-- 6. ПОДКЛЮЧАЕМ КНОПКИ
-- ===================================================
-- Кнопка сканирования
scanButton.MouseButton1Click:Connect(function()
	local structure = getProjectStructure()
	textBox.Text = structure
	-- Очищаем выделение после сканирования
	textBox.CursorPosition = -1
end)

-- Кнопка "Выделить текст"
copyButton.MouseButton1Click:Connect(function()
	-- Устанавливаем фокус на текстовое поле
	textBox:CaptureFocus()
	-- Выделяем весь текст
	textBox:SelectAll()
	
	-- Визуальный фидбек
	local originalColor = copyButton.BackgroundColor3
	copyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	wait(0.2)
	copyButton.BackgroundColor3 = originalColor
	
	-- Обновляем подсказку
	hintLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	hintLabel.Text = "✅ Текст выделен! Теперь нажми Ctrl+C (Cmd+C на Mac)"
	wait(2)
	hintLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	hintLabel.Text = "👉 Выдели текст и нажми Ctrl+C (Cmd+C на Mac) чтобы скопировать"
end)

-- Кнопка с инструкцией
copyInstructionsBtn.MouseButton1Click:Connect(function()
	-- Показываем подробную инструкцию во всплывающем окне
	local message = "КАК СКОПИРОВАТЬ СТРУКТУРУ:\n\n" ..
					"1. Нажми кнопку 'Выделить текст'\n" ..
					"2. Нажми Ctrl+C (на Windows/Linux)\n" ..
					"   или Cmd+C (на Mac)\n\n" ..
					"3. Вставь текст в чат с ИИ (Ctrl+V / Cmd+V)\n\n" ..
					"❗ В Roblox Studio нет прямого доступа к буферу обмена, поэтому нужно использовать системные комбинации клавиш."
	
	textBox.Text = message
end)

-- ===================================================
-- 7. УПРАВЛЕНИЕ ВИДИМОСТЬЮ ОКНА
-- ===================================================
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

plugin.Unloading:Connect(function()
	button:Destroy()
	widget:Destroy()
end)

print("✅ Structure Scanner Plugin с улучшенным копированием загружен!")