-- ===================================================
-- ПЛАГИН: Structure Scanner for AI (Улучшенный вывод)
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
	500,   -- Ширина окна (увеличил для удобства)
	400,   -- Высота окна
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
textBox.Size = UDim2.new(1, -20, 1, -60)
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
scanButton.Size = UDim2.new(0.5, -15, 0, 30)
scanButton.Position = UDim2.new(0, 10, 1, -40)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "Scan Project"
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 16
scanButton.Parent = mainFrame

-- Кнопка "Copy to Clipboard"
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0.5, -15, 0, 30)
copyButton.Position = UDim2.new(0.5, 5, 1, -40)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Text = "Copy to Clipboard"
copyButton.Font = Enum.Font.GothamBold
copyButton.TextSize = 16
copyButton.Parent = mainFrame

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
		-- Сокращаем некоторые распространенные классы для читаемости
		local friendlyNames = {
			BasePart = "Part",
			MeshPart = "Mesh",
			WedgePart = "Wedge",
			CylinderPart = "Cylinder",
			BallPart = "Ball",
			ModuleScript = "Module",
			LocalScript = "Local",
			Script = "Script"
		}
		return friendlyNames[className] or className
	end
	
	-- Рекурсивная функция для построения дерева
	local function scanObject(obj, level, isLast, prefix)
		prefix = prefix or ""
		
		-- Определяем символы для веток
		local currentPrefix = prefix
		local line = ""
		
		if level > 0 then
			-- Для корневых элементов (сервисов) используем "├──" или "└──"
			if isLast then
				line = prefix .. "└── "
				prefix = prefix .. "    "
			else
				line = prefix .. "├── "
				prefix = prefix .. "│   "
			end
		end
		
		-- Добавляем имя объекта и его тип
		local objName = obj.Name
		local objType = getFriendlyClassName(obj)
		line = line .. objName .. " (" .. objType .. ")"
		
		table.insert(resultLines, line)
		
		-- Рекурсивно обрабатываем детей
		local children = obj:GetChildren()
		if #children > 0 then
			-- Сортируем детей: папки и модели сначала, потом остальное
			table.sort(children, function(a, b)
				local aIsContainer = a:IsA("Folder") or a:IsA("Model")
				local bIsContainer = b:IsA("Folder") or b:IsA("Model")
				if aIsContainer ~= bIsContainer then
					return aIsContainer
				end
				return a.Name < b.Name
			end)
			
			for i, child in ipairs(children) do
				-- Пропускаем служебные объекты с подчеркиванием в начале
				if child.Name:sub(1, 1) ~= "_" then
					scanObject(child, level + 1, i == #children, prefix)
				end
			end
		end
	end
	
	-- Сканируем каждый корневой сервис
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
end)

-- Улучшенная кнопка копирования
copyButton.MouseButton1Click:Connect(function()
	-- Способ 1: Через фокус и копирование (надежнее)
	textBox:CaptureFocus()
	textBox:SelectAll()
	wait(0.1)
	textBox:Copy()
	
	-- Визуальный фидбек
	local originalColor = copyButton.BackgroundColor3
	copyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	wait(0.3)
	copyButton.BackgroundColor3 = originalColor
	
	-- Показываем сообщение что скопировано
	textBox.Text = textBox.Text .. "\n\n✅ Скопировано в буфер обмена!"
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

print("✅ Structure Scanner Plugin с улучшенным выводом загружен!")