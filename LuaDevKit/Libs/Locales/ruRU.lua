--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

local L = ns:NewLocale('ruRU')
if not L then return end

-- Untranslated keys fall back to enUS.
L['LuaDevKit Code Editor'] = 'Редактор кода LuaDevKit'
L['Wrap Text'] = 'Перенос строк'
L['Wrap Text::Desc'] =
  'Переносить длинные строки по ширине редактора вместо горизонтальной прокрутки.'
L['Resize Output'] = 'Размер панели вывода'
L['Resize Output::Desc'] =
  'Перетащите, чтобы изменить размер панели вывода. Стрелки разворачивают или сворачивают ее.'
L['Double-click to maximize'] = 'Двойной щелчок: развернуть'
L['Double-click to minimize'] = 'Двойной щелчок: свернуть'
L['Maximize Output'] = 'Развернуть вывод'
L['Maximize Output::Desc'] =
  'Развернуть панель вывода до максимального размера.'
L['Minimize Output'] = 'Свернуть вывод'
L['Minimize Output::Desc'] =
  'Свернуть панель вывода до минимального размера.'
L['Theme'] = 'Тема'
L['Theme::Desc'] = 'Выбрать тему оформления редактора.'
L['Font Family'] = 'Шрифт'
L['Font Family::Desc'] = 'Выбрать шрифт редактора.'
L['Font Size'] = 'Размер шрифта'
L['Font Size::Desc'] = 'Выбрать размер шрифта редактора.'
L['Increase Font Size'] = 'Увеличить шрифт'
L['Increase Font Size::Desc'] =
  'Увеличить шрифт редактора до следующего размера.'
L['Decrease Font Size'] = 'Уменьшить шрифт'
L['Decrease Font Size::Desc'] =
  'Уменьшить шрифт редактора до предыдущего размера.'
L['Command Line'] = 'Командная строка'
L['Command Line::Desc'] =
  'Выполнить одну строку Lua и вывести результат на панель вывода.'
L['Command Line::HelpTip'] = 'Выполните здесь строку Lua'
L['Command History'] = 'История команд'
L['Command History::Desc'] =
  'Выберите прежнюю команду, чтобы вернуть ее в командную строку.'
L['Command History::HelpTip'] = 'Выберите здесь недавнюю команду'
L['No Command History'] = 'История команд пуста'
L['Console Settings'] = 'Настройки консоли'
L['Console Settings::Desc'] =
  'Выбрать шрифт и размер для панели вывода и командной строки.'
L['Console Font'] = 'Шрифт консоли'
L['Console Font Size'] = 'Размер шрифта консоли'
L['Same as Editor'] = 'Как в редакторе'
L['Clear Output'] = 'Очистить вывод'
L['Clear Output::Desc'] = 'Удалить весь текст с панели вывода.'
L['Editor Helpers'] = 'Вспомогательные функции'
L['Editor Helpers::Desc'] =
  'Встроенные функции для кода в редакторе и в командной строке.'
L['Editor Helpers::p'] = 'Вывести на панель вывода'
L['Editor Helpers::t'] = 'Трассировка в /etrace'
L['Editor Helpers::fm'] =
  'Форматировать значение в несколько строк с отступами'
L['Editor Helpers::fs'] = 'Форматировать значение в одну строку'
L['Editor Helpers::fv'] =
  'Показать ключи и значения таблицы парами key=value'
L['Editor Helpers::inspect'] = 'Вычислить <val> в Table Inspector от Blizzard'
L['Editor Helpers::help'] = 'Вывести этот список'
L['inspect: expected a table, got %s'] =
  'inspect: ожидалась таблица, получено %s'
L['Editor Helpers::Hint'] =
  'Щелкните, чтобы вывести этот список на панель вывода'
L['Run'] = 'Выполнить'
L['Run::Desc'] =
  'Выполнить код из редактора и вывести результат на панель вывода.'
L['Run::Hint'] = 'Ctrl+1: выполнить, когда курсор в редакторе'
L['Run::Hint::Mac'] = 'Cmd+1: выполнить, когда курсор в редакторе'
L['Run::HelpTip'] = 'Запустите свой код'
L['New Document'] = 'Новый документ'
L['New Document::Desc'] = 'Создать новый пустой документ Lua.'
L['Save Document'] = 'Сохранить документ'
L['Save Document::Desc'] = 'Сохранить этот документ.'
L['Save Document::Hint'] = 'Нет несохраненных изменений'
L['Delete Document'] = 'Удалить документ'
L['Delete Document::Desc'] = 'Удалить этот документ.'
L['Delete "%s"?'] = 'Удалить «%s»?'
L['Delete'] = 'Удалить'
L['Open Document'] = 'Открыть документ'
L['Open Document::Desc'] =
  'Переключиться на другой документ; стрелки перебирают документы.'
L['Open Document::Hint'] =
  'Shift-щелчок: переименовать\nAlt-щелчок: сохранить как новый документ'
L['Rename Document'] = 'Переименовать документ'
L['Save Document As'] = 'Сохранить документ как'
L['%s Copy'] = '%s (копия)'
L['Untitled'] = 'Без имени'
L['Show Toolbar'] = 'Показывать панель инструментов'
L['Show Toolbar::Desc'] =
  'Показывать панель инструментов над областью кода.'
L['Options::HelpTip'] = 'Здесь больше настроек'
L['Skip Tour'] = 'Пропустить обзор'
L['Save on Run'] = 'Сохранять при запуске'
L['Save on Run::Desc'] = 'Сохранять документ при каждом запуске.'
L['Output Panel'] = 'Панель вывода'
L['Output Panel::Desc'] =
  'Показывать панель вывода под кодом или справа от него.'
L['Output Panel::Hint::Right'] =
  'Щелкните, чтобы переместить панель вправо'
L['Output Panel::Hint::Bottom'] =
  'Щелкните, чтобы переместить панель вниз'
L['Bottom'] = 'Снизу'
L['Right'] = 'Справа'
L['Profile'] = 'Профиль'
L['This'] = 'Этот'
L['Manage Profiles...'] = 'Управление профилями...'
L['Requires %s'] = 'Требуется %s'
L['Reset Profile::Confirm'] =
  'Сбросить %s? Все документы этого профиля будут удалены. Это действие нельзя отменить.'
L['Copy From::Confirm'] =
  'Скопировать документы из %s? Все документы этого профиля будут заменены. Это действие нельзя отменить.'
L['Save changes to "%s"?'] = 'Сохранить изменения в «%s»?'
L['Save'] = 'Сохранить'
L['Cancel'] = 'Отмена'
L['Discard'] = 'Не сохранять'
L['General'] = 'Общие'
L['Open Editor at Startup'] = 'Открывать редактор при запуске'
L['Open Editor at Startup::Desc'] =
  'Открывать редактор кода при входе в игру или перезагрузке интерфейса.'
L['Escape Key Closes Editor'] = 'Esc закрывает редактор'
L['Escape Key Closes Editor::Desc'] =
  'Клавиша Esc закрывает редактор кода. Если открыто окно настроек, Esc сначала закрывает его.'
L["Remember Blizzard's Table Inspector Location"] =
  'Запоминать положение Table Inspector от Blizzard'
L["Remember Blizzard's Table Inspector Location::Desc"] =
  'Открывать Table Inspector из inspect() или ti() там, куда его переместили в последний раз, а не по центру.'
L['Available commands:'] = 'Доступные команды:'
L['displays the addon info'] = 'показывает информацию об аддоне'
L['toggles the Code Editor'] =
  'открывает или закрывает редактор кода'
L['toggles the settings window'] =
  'открывает или закрывает окно настроек'
