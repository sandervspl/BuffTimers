local BuffTimers = LibStub("AceAddon-3.0"):NewAddon("BuffTimers")

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "enUS", true)
if L then
    L["Show seconds"] = "Show seconds"
    L["Show seconds below this time"] = "Show seconds below this time"
    L["Show milliseconds below 5 seconds"] = "Show milliseconds below 5 seconds"
    L["Always yellow text color"] = "Always yellow text color"
    L["Time Stamp Format"] = "Time Stamp Format"
    L["Add more colors to the timer"] = "Add more colors to the timer"
    L["Text vertical position"] = "Text vertical position"
    L["Customize text"] = "Customize text"
    L["Adjust the font size of the timer text"] = "Adjust the font size of the timer text"
    L["Adjust the vertical position of the timer text"] = "Adjust the vertical position of the timer text"
    L["Enable text customization"] = "Enable text customization"
    L["Use different colors based on remaining time"] = "Use different colors based on remaining time"
    L["Always use yellow for buff timer text"] = "Always use yellow for buff timer text"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Show milliseconds for buff timers with less than 5 seconds remaining"
    L["Only show seconds when buffs have less than this many minutes"] = "Only show seconds when buffs have less than this many minutes"
    L["Show seconds for buff timers"] = "Show seconds for buff timers"
    L["Choose the format for displaying buff duration"] = "Choose the format for displaying buff duration"
    L["Enable"] = "Enable"
    L["Format"] = "Format"
    L["Seconds"] = "Seconds"
    L["Color"] = "Color"
    L["Customization"] = "Customization"
    L["Time"] = "Time"
    L["Text"] = "Text"
    L["Font"] = "Font"
    L["Choose the font for the timer text"] = "Choose the font for the timer text"
    L["Font Size"] = "Font Size"
    L["Outline"] = "Outline"
    L["Choose the outline for the timer text"] = "Choose the outline for the timer text"
    L["Import / Export"] = "Import / Export"
    L["Share or restore the currently active profile."] = "Share or restore the currently active profile."
    L["Export string"] = "Export string"
    L["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."
    L["Select for copying"] = "Select for copying"
    L["Select the export string, then press Ctrl+C to copy it."] = "Select the export string, then press Ctrl+C to copy it."
    L["Export string selected. Press Ctrl+C to copy it."] = "Export string selected. Press Ctrl+C to copy it."
    L["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."
    L["Import string"] = "Import string"
    L["Paste a BuffTimers profile string here."] = "Paste a BuffTimers profile string here."
    L["Import profile"] = "Import profile"
    L["A profile with this name already exists and will be replaced. Continue?"] = "A profile with this name already exists and will be replaced. Continue?"
    L["The profile was imported successfully."] = "The profile was imported successfully."
    L["Paste a profile string first."] = "Paste a profile string first."
    L["The profile string is too long."] = "The profile string is too long."
    L["This is not a BuffTimers profile string."] = "This is not a BuffTimers profile string."
    L["This profile string uses an unsupported version (%s)."] = "This profile string uses an unsupported version (%s)."
    L["The profile string is damaged or incomplete."] = "The profile string is damaged or incomplete."
    L["The profile data is invalid."] = "The profile data is invalid."
    L["The profile contains an invalid value for %s."] = "The profile contains an invalid value for %s."
end

-- Russian translation
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ruRU")
if L then
    L["Show seconds below this time"] = "Показывать секунды, когда остаётся меньше этого времени"
    L["Show seconds"] = "Показать секунды"
    L["Show milliseconds below 5 seconds"] = "Показывать миллисекунды, когда осталось меньше 5 секунд"
    L["Always yellow text color"] = "Всегда желтый цвет текста"
    L["Time Stamp Format"] = "Формат отметки времени"
    L["Add more colors to the timer"] = "Добавить больше цветов к таймеру"
    L["Text vertical position"] = "Вертикальное положение текста"
    L["Customize text"] = "Настроить текст"
    L["Adjust the font size of the timer text"] = "Настроить размер шрифта текста таймера"
    L["Adjust the vertical position of the timer text"] = "Настроить вертикальное положение текста таймера"
    L["Enable text customization"] = "Включить настройку текста"
    L["Use different colors based on remaining time"] = "Использовать разные цвета в зависимости от оставшегося времени"
    L["Always use yellow for buff timer text"] = "Всегда использовать желтый цвет для текста таймера баффа"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Показывать миллисекунды для таймеров баффов, у которых осталось меньше 5 секунд"
    L["Only show seconds when buffs have less than this many minutes"] = "Показывать секунды только тогда, когда у баффов меньше указанного количества минут"
    L["Show seconds for buff timers"] = "Показывать секунды для таймеров баффов"
    L["Choose the format for displaying buff duration"] = "Выберите формат для отображения продолжительности баффа"
    L["Enable"] = "Включить"
    L["Format"] = "Формат"
    L["Seconds"] = "Секунды"
    L["Color"] = "Цвет"
    L["Customization"] = "Настройка"
    L["Time"] = "Время"
    L["Text"] = "Текст"
    L["Font"] = "Шрифт"
    L["Choose the font for the timer text"] = "Выберите шрифт для текста таймера"
    L["Font Size"] = "Размер шрифта"
    L["Outline"] = "Контур"
    L["Choose the outline for the timer text"] = "Выберите контур для текста таймера"
end

-- German translation by: ysjoelfir
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "deDE")
if L then
    L["Show seconds"] = "Sekunden anzeigen"
    L["Show seconds below this time"] = "Sekunden unterhalb dieses Zeitwerts anzeigen"
    L["Show milliseconds below 5 seconds"] = "Zeige Millisekunden unter 5 Sekunden"
    L["Always yellow text color"] = "Textfarbe immer gelb"
    L["Time Stamp Format"] = "Zeitstempelformat"
    L["Add more colors to the timer"] = "Füge mehr Farben zum Timer hinzu"
    L["Text vertical position"] = "Text vertikale Position"
    L["Customize text"] = "Text anpassen"
    L["Adjust the font size of the timer text"] = "Schriftgröße des Timer-Texts anpassen"
    L["Adjust the vertical position of the timer text"] = "Vertikale Position des Timer-Texts anpassen"
    L["Enable text customization"] = "Text anpassen"
    L["Use different colors based on remaining time"] = "Verwende verschiedene Farben basierend auf der verbleibenden Zeit"
    L["Always use yellow for buff timer text"] = "Textfarbe immer gelb"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Zeige Millisekunden für Buff-Timer mit weniger als 5 Sekunden verbleibend"
    L["Only show seconds when buffs have less than this many minutes"] = "Zeige Sekunden nur wenn Buffs weniger als diese Minuten verbleiben"
    L["Show seconds for buff timers"] = "Zeige Sekunden für Buff-Timer"
    L["Choose the format for displaying buff duration"] = "Wähle das Format für die Anzeige der Buff-Dauer"
    L["Enable"] = "Aktivieren"
    L["Format"] = "Format"
    L["Seconds"] = "Sekunden"
    L["Color"] = "Farbe"
    L["Customization"] = "Anpassung"
    L["Time"] = "Zeit"
    L["Text"] = "Text"
    L["Font"] = "Schriftart"
    L["Choose the font for the timer text"] = "Wähle die Schriftart für den Timer-Text"
    L["Font Size"] = "Schriftgröße"
    L["Outline"] = "Umriss"
    L["Choose the outline for the timer text"] = "Wähle den Umriss für den Timer-Text"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ptPT")
if L then
    L["Show seconds"] = "Mostrar segundos"
    L["Show seconds below this time"] = "Mostrar segundos abaixo deste tempo"
    L["Show milliseconds below 5 seconds"] = "Mostrar milisegundos abaixo de 5 segundos"
    L["Always yellow text color"] = "Cor de texto sempre amarela"
    L["Time Stamp Format"] = "Formato da hora"
    L["Add more colors to the timer"] = "Adicionar mais cores ao temporizador"
    L["Text vertical position"] = "Posição vertical do texto"
    L["Customize text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar o tamanho da fonte do texto do temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar a posição vertical do texto do temporizador"
    L["Enable text customization"] = "Habilitar personalização de texto"
    L["Use different colors based on remaining time"] = "Usar cores diferentes com base no tempo restante"
    L["Always use yellow for buff timer text"] = "Texto sempre amarelo para o temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milissegundos para temporizadores de buff com menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos apenas quando os buffs têm menos deste número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escolha o formato para exibir a duração do buff"
    L["Enable"] = "Ativar"
    L["Format"] = "Formato"
    L["Seconds"] = "Segundos"
    L["Color"] = "Cor"
    L["Customization"] = "Personalização"
    L["Time"] = "Tempo"
    L["Text"] = "Texto"
    L["Font"] = "Fonte"
    L["Choose the font for the timer text"] = "Escolha a fonte para o texto do temporizador"
    L["Font Size"] = "Tamanho da fonte"
    L["Outline"] = "Contorno"
    L["Choose the outline for the timer text"] = "Escolha o contorno para o texto do temporizador"
end

-- French translation by: qrpino
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "frFR")
if L then
    L["Show seconds"] = "Afficher les secondes"
    L["Show seconds below this time"] = "Afficher les secondes en dessous de cette durée"
    L["Show milliseconds below 5 seconds"] = "Afficher les millisecondes sous 5 secondes"
    L["Always yellow text color"] = "Couleur du texte toujours jaune"
    L["Time Stamp Format"] = "Format de l'horodatage"
    L["Add more colors to the timer"] = "Ajouter plus de couleurs au minuteur"
    L["Text vertical position"] = "Position verticale du texte"
    L["Customize text"] = "Personnaliser le texte"
    L["Adjust the font size of the timer text"] = "Ajuster la taille de la police du texte du minuteur"
    L["Adjust the vertical position of the timer text"] = "Ajuster la position verticale du texte du minuteur"
    L["Enable text customization"] = "Activer la personnalisation du texte"
    L["Use different colors based on remaining time"] = "Utiliser différentes couleurs en fonction du temps restant"
    L["Always use yellow for buff timer text"] = "Texte toujours jaune pour le minuteur de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Afficher les millisecondes pour les minuteurs de buff avec moins de 5 secondes restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Afficher les secondes uniquement lorsque les buffs ont moins de ce nombre de minutes"
    L["Show seconds for buff timers"] = "Afficher les secondes pour les minuteurs de buff"
    L["Choose the format for displaying buff duration"] = "Choisir le format pour afficher la durée du buff"
    L["Enable"] = "Activer"
    L["Format"] = "Format"
    L["Seconds"] = "Secondes"
    L["Color"] = "Couleur"
    L["Customization"] = "Personnalisation"
    L["Time"] = "Temps"
    L["Text"] = "Texte"
    L["Font"] = "Police"
    L["Choose the font for the timer text"] = "Choisir la police pour le texte du minuteur"
    L["Font Size"] = "Taille de police"
    L["Outline"] = "Contour"
    L["Choose the outline for the timer text"] = "Choisir le contour pour le texte du minuteur"
end

--
-- HELP!
-- I need help with all the languages below.
-- Right now, everything has been translated by AI, so it might not be correct.
--

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "esES")
if L then
    L["Show seconds"] = "Mostrar segundos"
    L["Show seconds below this time"] = "Mostrar segundos por debajo de este tiempo"
    L["Show milliseconds below 5 seconds"] = "Mostrar los milisegundos bajo 5 segundos"
    L["Always yellow text color"] = "Siempre color texto amarillo"
    L["Time Stamp Format"] = "Formato de la hora"
    L["Add more colors to the timer"] = "Añadir más colores al temporizador"
    L["Text vertical position"] = "Posición vertical del texto"
    L["Customize text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar el tamaño de la fuente del texto del temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar la posición vertical del texto del temporizador"
    L["Enable text customization"] = "Habilitar la personalización del texto"
    L["Use different colors based on remaining time"] = "Usar colores diferentes según el tiempo restante"
    L["Always use yellow for buff timer text"] = "Texto siempre amarillo para el temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milisegundos para temporizadores de buff con menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos solo cuando los buffs tienen menos de este número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escoge el formato para mostrar la duración del buff"
    L["Enable"] = "Habilitar"
    L["Format"] = "Formato"
    L["Seconds"] = "Segundos"
    L["Color"] = "Color"
    L["Customization"] = "Personalización"
    L["Time"] = "Tiempo"
    L["Text"] = "Texto"
    L["Font"] = "Fuente"
    L["Choose the font for the timer text"] = "Elige la fuente para el texto del temporizador"
    L["Font Size"] = "Tamaño de fuente"
    L["Outline"] = "Contorno"
    L["Choose the outline for the timer text"] = "Elige el contorno para el texto del temporizador"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "esMX")
if L then
    L["Show seconds"] = "Mostrar segundos"
    L["Show seconds below this time"] = "Mostrar segundos por debajo de este tiempo"
    L["Show milliseconds below 5 seconds"] = "Mostrar los milisegundos bajo 5 segundos"
    L["Always yellow text color"] = "Siempre color texto amarillo"
    L["Time Stamp Format"] = "Formato de la hora"
    L["Add more colors to the timer"] = "Añadir más colores al temporizador"
    L["Text vertical position"] = "Posición vertical del texto"
    L["Customize text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar el tamaño de la fuente del texto del temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar la posición vertical del texto del temporizador"
    L["Enable text customization"] = "Habilitar la personalización del texto"
    L["Use different colors based on remaining time"] = "Usar colores diferentes según el tiempo restante"
    L["Always use yellow for buff timer text"] = "Texto siempre amarillo para el temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milisegundos para temporizadores de buff con menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos solo cuando los buffs tienen menos de este número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escoge el formato para mostrar la duración del buff"
    L["Enable"] = "Habilitar"
    L["Format"] = "Formato"
    L["Seconds"] = "Segundos"
    L["Color"] = "Color"
    L["Customization"] = "Personalización"
    L["Time"] = "Tiempo"
    L["Text"] = "Texto"
    L["Font"] = "Fuente"
    L["Choose the font for the timer text"] = "Elige la fuente para el texto del temporizador"
    L["Font Size"] = "Tamaño de fuente"
    L["Outline"] = "Contorno"
    L["Choose the outline for the timer text"] = "Elige el contorno para el texto del temporizador"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "itIT")
if L then
    L["Show seconds"] = "Mostra secondi"
    L["Show seconds below this time"] = "Mostra i secondi al di sotto di questo tempo"
    L["Show milliseconds below 5 seconds"] = "Mostra millisecondi sotto 5 secondi"
    L["Always yellow text color"] = "Sempre colore testo giallo"
    L["Time Stamp Format"] = "Formato dell'ora"
    L["Add more colors to the timer"] = "Aggiungi più colori al timer"
    L["Text vertical position"] = "Posizione verticale del testo"
    L["Customize text"] = "Personalizza testo"
    L["Adjust the font size of the timer text"] = "Ajusta la dimensione del carattere del testo del timer"
    L["Adjust the vertical position of the timer text"] = "Ajusta la posizione verticale del testo del timer"
    L["Enable text customization"] = "Abilita la personalizzazione del testo"
    L["Use different colors based on remaining time"] = "Usa colori diversi in base al tempo rimanente"
    L["Always use yellow for buff timer text"] = "Testo sempre giallo per il timer di buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostra millisecondi per i timer di buff con meno di 5 secondi rimanenti"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostra solo secondi quando i buff hanno meno di questo numero di minuti"
    L["Show seconds for buff timers"] = "Mostra secondi per i timer di buff"
    L["Choose the format for displaying buff duration"] = "Scegli il formato per visualizzare la durata del buff"
    L["Enable"] = "Abilitare"
    L["Format"] = "Formato"
    L["Seconds"] = "Secondi"
    L["Color"] = "Colore"
    L["Customization"] = "Personalizzazione"
    L["Time"] = "Tempo"
    L["Text"] = "Testo"
    L["Font"] = "Carattere"
    L["Choose the font for the timer text"] = "Scegli il carattere per il testo del timer"
    L["Font Size"] = "Dimensione carattere"
    L["Outline"] = "Contorno"
    L["Choose the outline for the timer text"] = "Scegli il contorno per il testo del timer"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "koKR")
if L then
    L["Show seconds below this time"] = "이 시간 미만일 때 초 표시"
    L["Show seconds"] = "초 보기"
    L["Show milliseconds below 5 seconds"] = "5초 이하 마이크로초 보기"
    L["Always yellow text color"] = "항상 노란색 텍스트 색상"
    L["Time Stamp Format"] = "시간 표시 형식"
    L["Add more colors to the timer"] = "타이머에 더 많은 색상 추가"
    L["Text vertical position"] = "텍스트 수직 위치"
    L["Customize text"] = "텍스트 사용자 정의"
    L["Adjust the font size of the timer text"] = "타이머 텍스트의 글꼴 크기 조정"
    L["Adjust the vertical position of the timer text"] = "타이머 텍스트의 수직 위치 조정"
    L["Enable text customization"] = "텍스트 사용자 정의 활성화"
    L["Use different colors based on remaining time"] = "남은 시간에 따라 다른 색상 사용"
    L["Always use yellow for buff timer text"] = "항상 노란색 텍스트 색상"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "5초 이하 마이크로초 보기"
    L["Only show seconds when buffs have less than this many minutes"] = "5초 이하 마이크로초 보기"
    L["Show seconds for buff timers"] = "초 보기"
    L["Choose the format for displaying buff duration"] = "초 보기"
    L["Enable"] = "활성화"
    L["Format"] = "형식"
    L["Seconds"] = "초"
    L["Color"] = "색상"
    L["Customization"] = "사용자 정의"
    L["Time"] = "시간"
    L["Text"] = "텍스트"
    L["Font"] = "글꼴"
    L["Choose the font for the timer text"] = "타이머 텍스트의 글꼴 선택"
    L["Font Size"] = "글꼴 크기"
    L["Outline"] = "외곽선"
    L["Choose the outline for the timer text"] = "타이머 텍스트의 외곽선 선택"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ptBR")
if L then
    L["Show seconds"] = "Mostrar segundos"
    L["Show seconds below this time"] = "Mostrar segundos abaixo deste tempo"
    L["Show milliseconds below 5 seconds"] = "Mostrar milisegundos abaixo de 5 segundos"
    L["Always yellow text color"] = "Sempre cor de texto amarela"
    L["Time Stamp Format"] = "Formato da hora"
    L["Add more colors to the timer"] = "Adicionar mais cores ao temporizador"
    L["Text vertical position"] = "Posição vertical do texto"
    L["Customize text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar o tamanho da fonte do texto do temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar a posição vertical do texto do temporizador"
    L["Enable text customization"] = "Habilitar a personalização do texto"
    L["Use different colors based on remaining time"] = "Usar cores diferentes com base no tempo restante"
    L["Always use yellow for buff timer text"] = "Texto sempre amarelo para o temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milissegundos para temporizadores de buff com menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos apenas quando os buffs têm menos deste número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escolha o formato para exibir a duração do buff"
    L["Enable"] = "Ativar"
    L["Format"] = "Formato"
    L["Seconds"] = "Segundos"
    L["Color"] = "Cor"
    L["Customization"] = "Personalização"
    L["Time"] = "Tempo"
    L["Text"] = "Texto"
    L["Font"] = "Fonte"
    L["Choose the font for the timer text"] = "Escolha a fonte para o texto do temporizador"
    L["Font Size"] = "Tamanho da fonte"
    L["Outline"] = "Contorno"
    L["Choose the outline for the timer text"] = "Escolha o contorno para o texto do temporizador"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "zhCN")
if L then
    L["Show seconds"] = "显示秒"
    L["Show seconds below this time"] = "小于此时间才显示秒"
    L["Show milliseconds below 5 seconds"] = "小于5秒显示毫秒"
    L["Always yellow text color"] = "文字颜色总是使用黄色"
    L["Time Stamp Format"] = "时间格式"
    L["Add more colors to the timer"] = "计时器显示更多颜色"
    L["Text vertical position"] = "文字垂直位置"
    L["Customize text"] = "自定义文字"
    L["Adjust the font size of the timer text"] = "调整计时器文字大小"
    L["Adjust the vertical position of the timer text"] = "调整计时器文字垂直位置"
    L["Enable text customization"] = "启用文字自定义"
    L["Use different colors based on remaining time"] = "根据剩余时间使用不同颜色"
    L["Always use yellow for buff timer text"] = "文字颜色总是使用黄色"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "显示毫秒计时器，当剩余时间小于5秒时"
    L["Only show seconds when buffs have less than this many minutes"] = "只显示秒，当buff剩余时间小于此分钟数时"
    L["Show seconds for buff timers"] = "显示秒计时器"
    L["Choose the format for displaying buff duration"] = "选择显示buff持续时间的格式"
    L["Enable"] = "启用"
    L["Format"] = "格式"
    L["Seconds"] = "秒"
    L["Color"] = "颜色"
    L["Customization"] = "自定义"
    L["Time"] = "时间"
    L["Text"] = "文本"
    L["Font"] = "字体"
    L["Choose the font for the timer text"] = "选择计时器文字的字体"
    L["Font Size"] = "字体大小"
    L["Outline"] = "描边"
    L["Choose the outline for the timer text"] = "选择计时器文字的描边"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "zhTW")
if L then
    L["Show seconds"] = "顯示秒"
    L["Show seconds below this time"] = "小於此時間才顯示秒"
    L["Show milliseconds below 5 seconds"] = "小於5秒才顯示毫秒"
    L["Always yellow text color"] = "文字顔色總是使用黃色"
    L["Time Stamp Format"] = "時間格式"
    L["Add more colors to the timer"] = "計時器顯示更多顔色"
    L["Text vertical position"] = "文字垂直位置"
    L["Customize text"] = "自定義文字"
    L["Adjust the font size of the timer text"] = "調整計時器文字大小"
    L["Adjust the vertical position of the timer text"] = "調整計時器文字垂直位置"
    L["Enable text customization"] = "啟用文字自訂"
    L["Use different colors based on remaining time"] = "根據剩餘時間使用不同顏色"
    L["Always use yellow for buff timer text"] = "文字顏色總是使用黃色"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "顯示毫秒計時器，當剩餘時間小於5秒時"
    L["Only show seconds when buffs have less than this many minutes"] = "只顯示秒，當buff剩餘時間小於此分鐘數時"
    L["Show seconds for buff timers"] = "顯示秒計時器"
    L["Choose the format for displaying buff duration"] = "選擇顯示buff持續時間的格式"
    L["Enable"] = "啟用"
    L["Format"] = "格式"
    L["Seconds"] = "秒"
    L["Color"] = "顏色"
    L["Customization"] = "自訂"
    L["Time"] = "時間"
    L["Text"] = "文字"
    L["Font"] = "字體"
    L["Choose the font for the timer text"] = "選擇計時器文字的字體"
    L["Font Size"] = "字體大小"
    L["Outline"] = "描邊"
    L["Choose the outline for the timer text"] = "選擇計時器文字的描邊"
end

-- Profile import/export translations are kept together so every locale receives
-- the complete set added after the original options were translated.
local profileStrings = {
    ruRU = {
        ["Import / Export"] = "Импорт / экспорт", ["Share or restore the currently active profile."] = "Поделиться текущим активным профилем или восстановить его.", ["Export string"] = "Строка экспорта", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Щёлкните поле и нажмите Ctrl+A, затем Ctrl+C, чтобы скопировать активный профиль.", ["Select for copying"] = "Выбрать для копирования", ["Select the export string, then press Ctrl+C to copy it."] = "Выберите строку экспорта и нажмите Ctrl+C, чтобы скопировать её.", ["Export string selected. Press Ctrl+C to copy it."] = "Строка экспорта выбрана. Нажмите Ctrl+C, чтобы скопировать её.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Не удалось выбрать строку экспорта. Щёлкните поле и нажмите Ctrl+A, затем Ctrl+C.", ["Import string"] = "Строка импорта", ["Paste a BuffTimers profile string here."] = "Вставьте сюда строку профиля BuffTimers.", ["Import profile"] = "Импортировать профиль", ["A profile with this name already exists and will be replaced. Continue?"] = "Профиль с таким именем уже существует и будет заменён. Продолжить?", ["The profile was imported successfully."] = "Профиль успешно импортирован.", ["Paste a profile string first."] = "Сначала вставьте строку профиля.", ["The profile string is too long."] = "Строка профиля слишком длинная.", ["This is not a BuffTimers profile string."] = "Это не строка профиля BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Эта строка профиля использует неподдерживаемую версию (%s).", ["The profile string is damaged or incomplete."] = "Строка профиля повреждена или неполна.", ["The profile data is invalid."] = "Данные профиля недействительны.", ["The profile contains an invalid value for %s."] = "Профиль содержит недопустимое значение для %s.",
    },
    deDE = {
        ["Import / Export"] = "Import / Export", ["Share or restore the currently active profile."] = "Das derzeit aktive Profil teilen oder wiederherstellen.", ["Export string"] = "Exportzeichenfolge", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Klicke in das Feld und drücke Strg+A, dann Strg+C, um das aktive Profil zu kopieren.", ["Select for copying"] = "Zum Kopieren auswählen", ["Select the export string, then press Ctrl+C to copy it."] = "Wähle die Exportzeichenfolge und drücke dann Strg+C, um sie zu kopieren.", ["Export string selected. Press Ctrl+C to copy it."] = "Exportzeichenfolge ausgewählt. Drücke Strg+C, um sie zu kopieren.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Die Exportzeichenfolge konnte nicht ausgewählt werden. Klicke in das Feld und drücke Strg+A, dann Strg+C.", ["Import string"] = "Importzeichenfolge", ["Paste a BuffTimers profile string here."] = "Füge hier eine BuffTimers-Profilzeichenfolge ein.", ["Import profile"] = "Profil importieren", ["A profile with this name already exists and will be replaced. Continue?"] = "Ein Profil mit diesem Namen existiert bereits und wird ersetzt. Fortfahren?", ["The profile was imported successfully."] = "Das Profil wurde erfolgreich importiert.", ["Paste a profile string first."] = "Füge zuerst eine Profilzeichenfolge ein.", ["The profile string is too long."] = "Die Profilzeichenfolge ist zu lang.", ["This is not a BuffTimers profile string."] = "Dies ist keine BuffTimers-Profilzeichenfolge.", ["This profile string uses an unsupported version (%s)."] = "Diese Profilzeichenfolge verwendet eine nicht unterstützte Version (%s).", ["The profile string is damaged or incomplete."] = "Die Profilzeichenfolge ist beschädigt oder unvollständig.", ["The profile data is invalid."] = "Die Profildaten sind ungültig.", ["The profile contains an invalid value for %s."] = "Das Profil enthält einen ungültigen Wert für %s.",
    },
    ptPT = {
        ["Import / Export"] = "Importar / Exportar", ["Share or restore the currently active profile."] = "Partilhe ou restaure o perfil ativo atual.", ["Export string"] = "Sequência de exportação", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Clique no campo e prima Ctrl+A e depois Ctrl+C para copiar o perfil ativo.", ["Select for copying"] = "Selecionar para copiar", ["Select the export string, then press Ctrl+C to copy it."] = "Selecione a sequência de exportação e prima Ctrl+C para a copiar.", ["Export string selected. Press Ctrl+C to copy it."] = "Sequência de exportação selecionada. Prima Ctrl+C para a copiar.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Não foi possível selecionar a sequência de exportação. Clique no campo e prima Ctrl+A e depois Ctrl+C.", ["Import string"] = "Sequência de importação", ["Paste a BuffTimers profile string here."] = "Cole aqui uma sequência de perfil do BuffTimers.", ["Import profile"] = "Importar perfil", ["A profile with this name already exists and will be replaced. Continue?"] = "Já existe um perfil com este nome e será substituído. Continuar?", ["The profile was imported successfully."] = "O perfil foi importado com sucesso.", ["Paste a profile string first."] = "Cole primeiro uma sequência de perfil.", ["The profile string is too long."] = "A sequência de perfil é demasiado longa.", ["This is not a BuffTimers profile string."] = "Esta não é uma sequência de perfil do BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Esta sequência de perfil usa uma versão não suportada (%s).", ["The profile string is damaged or incomplete."] = "A sequência de perfil está danificada ou incompleta.", ["The profile data is invalid."] = "Os dados do perfil são inválidos.", ["The profile contains an invalid value for %s."] = "O perfil contém um valor inválido para %s.",
    },
    frFR = {
        ["Import / Export"] = "Importer / Exporter", ["Share or restore the currently active profile."] = "Partagez ou restaurez le profil actuellement actif.", ["Export string"] = "Chaîne d’exportation", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Cliquez dans le champ, puis appuyez sur Ctrl+A et Ctrl+C pour copier le profil actif.", ["Select for copying"] = "Sélectionner pour copier", ["Select the export string, then press Ctrl+C to copy it."] = "Sélectionnez la chaîne d’exportation, puis appuyez sur Ctrl+C pour la copier.", ["Export string selected. Press Ctrl+C to copy it."] = "Chaîne d’exportation sélectionnée. Appuyez sur Ctrl+C pour la copier.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Impossible de sélectionner la chaîne d’exportation. Cliquez dans le champ, puis appuyez sur Ctrl+A et Ctrl+C.", ["Import string"] = "Chaîne d’importation", ["Paste a BuffTimers profile string here."] = "Collez ici une chaîne de profil BuffTimers.", ["Import profile"] = "Importer le profil", ["A profile with this name already exists and will be replaced. Continue?"] = "Un profil portant ce nom existe déjà et sera remplacé. Continuer ?", ["The profile was imported successfully."] = "Le profil a été importé avec succès.", ["Paste a profile string first."] = "Collez d’abord une chaîne de profil.", ["The profile string is too long."] = "La chaîne de profil est trop longue.", ["This is not a BuffTimers profile string."] = "Ce n’est pas une chaîne de profil BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Cette chaîne de profil utilise une version non prise en charge (%s).", ["The profile string is damaged or incomplete."] = "La chaîne de profil est endommagée ou incomplète.", ["The profile data is invalid."] = "Les données du profil sont invalides.", ["The profile contains an invalid value for %s."] = "Le profil contient une valeur invalide pour %s.",
    },
    esES = {
        ["Import / Export"] = "Importar / Exportar", ["Share or restore the currently active profile."] = "Comparte o restaura el perfil activo actual.", ["Export string"] = "Cadena de exportación", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Haz clic en el campo y pulsa Ctrl+A y después Ctrl+C para copiar el perfil activo.", ["Select for copying"] = "Seleccionar para copiar", ["Select the export string, then press Ctrl+C to copy it."] = "Selecciona la cadena de exportación y pulsa Ctrl+C para copiarla.", ["Export string selected. Press Ctrl+C to copy it."] = "Cadena de exportación seleccionada. Pulsa Ctrl+C para copiarla.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "No se pudo seleccionar la cadena de exportación. Haz clic en el campo y pulsa Ctrl+A y después Ctrl+C.", ["Import string"] = "Cadena de importación", ["Paste a BuffTimers profile string here."] = "Pega aquí una cadena de perfil de BuffTimers.", ["Import profile"] = "Importar perfil", ["A profile with this name already exists and will be replaced. Continue?"] = "Ya existe un perfil con este nombre y será reemplazado. ¿Continuar?", ["The profile was imported successfully."] = "El perfil se importó correctamente.", ["Paste a profile string first."] = "Pega primero una cadena de perfil.", ["The profile string is too long."] = "La cadena de perfil es demasiado larga.", ["This is not a BuffTimers profile string."] = "Esta no es una cadena de perfil de BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Esta cadena de perfil usa una versión no compatible (%s).", ["The profile string is damaged or incomplete."] = "La cadena de perfil está dañada o incompleta.", ["The profile data is invalid."] = "Los datos del perfil no son válidos.", ["The profile contains an invalid value for %s."] = "El perfil contiene un valor no válido para %s.",
    },
    esMX = {
        ["Import / Export"] = "Importar / Exportar", ["Share or restore the currently active profile."] = "Comparte o restaura el perfil activo actual.", ["Export string"] = "Cadena de exportación", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Haz clic en el campo y presiona Ctrl+A y luego Ctrl+C para copiar el perfil activo.", ["Select for copying"] = "Seleccionar para copiar", ["Select the export string, then press Ctrl+C to copy it."] = "Selecciona la cadena de exportación y presiona Ctrl+C para copiarla.", ["Export string selected. Press Ctrl+C to copy it."] = "Cadena de exportación seleccionada. Presiona Ctrl+C para copiarla.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "No se pudo seleccionar la cadena de exportación. Haz clic en el campo y presiona Ctrl+A y luego Ctrl+C.", ["Import string"] = "Cadena de importación", ["Paste a BuffTimers profile string here."] = "Pega aquí una cadena de perfil de BuffTimers.", ["Import profile"] = "Importar perfil", ["A profile with this name already exists and will be replaced. Continue?"] = "Ya existe un perfil con este nombre y será reemplazado. ¿Continuar?", ["The profile was imported successfully."] = "El perfil se importó correctamente.", ["Paste a profile string first."] = "Pega primero una cadena de perfil.", ["The profile string is too long."] = "La cadena de perfil es demasiado larga.", ["This is not a BuffTimers profile string."] = "Esta no es una cadena de perfil de BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Esta cadena de perfil usa una versión no compatible (%s).", ["The profile string is damaged or incomplete."] = "La cadena de perfil está dañada o incompleta.", ["The profile data is invalid."] = "Los datos del perfil no son válidos.", ["The profile contains an invalid value for %s."] = "El perfil contiene un valor no válido para %s.",
    },
    itIT = {
        ["Import / Export"] = "Importa / Esporta", ["Share or restore the currently active profile."] = "Condividi o ripristina il profilo attualmente attivo.", ["Export string"] = "Stringa di esportazione", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Fai clic nel campo e premi Ctrl+A, poi Ctrl+C per copiare il profilo attivo.", ["Select for copying"] = "Seleziona per copiare", ["Select the export string, then press Ctrl+C to copy it."] = "Seleziona la stringa di esportazione, poi premi Ctrl+C per copiarla.", ["Export string selected. Press Ctrl+C to copy it."] = "Stringa di esportazione selezionata. Premi Ctrl+C per copiarla.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Impossibile selezionare la stringa di esportazione. Fai clic nel campo e premi Ctrl+A, poi Ctrl+C.", ["Import string"] = "Stringa di importazione", ["Paste a BuffTimers profile string here."] = "Incolla qui una stringa di profilo di BuffTimers.", ["Import profile"] = "Importa profilo", ["A profile with this name already exists and will be replaced. Continue?"] = "Esiste già un profilo con questo nome e sarà sostituito. Continuare?", ["The profile was imported successfully."] = "Il profilo è stato importato correttamente.", ["Paste a profile string first."] = "Incolla prima una stringa di profilo.", ["The profile string is too long."] = "La stringa del profilo è troppo lunga.", ["This is not a BuffTimers profile string."] = "Questa non è una stringa di profilo di BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Questa stringa di profilo usa una versione non supportata (%s).", ["The profile string is damaged or incomplete."] = "La stringa del profilo è danneggiata o incompleta.", ["The profile data is invalid."] = "I dati del profilo non sono validi.", ["The profile contains an invalid value for %s."] = "Il profilo contiene un valore non valido per %s.",
    },
    koKR = {
        ["Import / Export"] = "가져오기 / 내보내기", ["Share or restore the currently active profile."] = "현재 활성화된 프로필을 공유하거나 복원합니다.", ["Export string"] = "내보내기 문자열", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "필드를 클릭하고 Ctrl+A, Ctrl+C를 차례로 눌러 활성 프로필을 복사합니다.", ["Select for copying"] = "복사용 선택", ["Select the export string, then press Ctrl+C to copy it."] = "내보내기 문자열을 선택한 다음 Ctrl+C를 눌러 복사합니다.", ["Export string selected. Press Ctrl+C to copy it."] = "내보내기 문자열이 선택되었습니다. Ctrl+C를 눌러 복사합니다.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "내보내기 문자열을 선택할 수 없습니다. 필드를 클릭하고 Ctrl+A, Ctrl+C를 차례로 누르세요.", ["Import string"] = "가져오기 문자열", ["Paste a BuffTimers profile string here."] = "여기에 BuffTimers 프로필 문자열을 붙여넣으세요.", ["Import profile"] = "프로필 가져오기", ["A profile with this name already exists and will be replaced. Continue?"] = "이 이름의 프로필이 이미 있으며 교체됩니다. 계속하시겠습니까?", ["The profile was imported successfully."] = "프로필을 성공적으로 가져왔습니다.", ["Paste a profile string first."] = "먼저 프로필 문자열을 붙여넣으세요.", ["The profile string is too long."] = "프로필 문자열이 너무 깁니다.", ["This is not a BuffTimers profile string."] = "BuffTimers 프로필 문자열이 아닙니다.", ["This profile string uses an unsupported version (%s)."] = "이 프로필 문자열은 지원하지 않는 버전(%s)을 사용합니다.", ["The profile string is damaged or incomplete."] = "프로필 문자열이 손상되었거나 불완전합니다.", ["The profile data is invalid."] = "프로필 데이터가 올바르지 않습니다.", ["The profile contains an invalid value for %s."] = "프로필에 %s에 대한 잘못된 값이 있습니다.",
    },
    ptBR = {
        ["Import / Export"] = "Importar / Exportar", ["Share or restore the currently active profile."] = "Compartilhe ou restaure o perfil atualmente ativo.", ["Export string"] = "Sequência de exportação", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "Clique no campo e pressione Ctrl+A, depois Ctrl+C, para copiar o perfil ativo.", ["Select for copying"] = "Selecionar para copiar", ["Select the export string, then press Ctrl+C to copy it."] = "Selecione a sequência de exportação e pressione Ctrl+C para copiá-la.", ["Export string selected. Press Ctrl+C to copy it."] = "Sequência de exportação selecionada. Pressione Ctrl+C para copiá-la.", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "Não foi possível selecionar a sequência de exportação. Clique no campo e pressione Ctrl+A, depois Ctrl+C.", ["Import string"] = "Sequência de importação", ["Paste a BuffTimers profile string here."] = "Cole aqui uma sequência de perfil do BuffTimers.", ["Import profile"] = "Importar perfil", ["A profile with this name already exists and will be replaced. Continue?"] = "Já existe um perfil com este nome e ele será substituído. Continuar?", ["The profile was imported successfully."] = "O perfil foi importado com sucesso.", ["Paste a profile string first."] = "Cole primeiro uma sequência de perfil.", ["The profile string is too long."] = "A sequência de perfil é longa demais.", ["This is not a BuffTimers profile string."] = "Esta não é uma sequência de perfil do BuffTimers.", ["This profile string uses an unsupported version (%s)."] = "Esta sequência de perfil usa uma versão sem suporte (%s).", ["The profile string is damaged or incomplete."] = "A sequência de perfil está danificada ou incompleta.", ["The profile data is invalid."] = "Os dados do perfil são inválidos.", ["The profile contains an invalid value for %s."] = "O perfil contém um valor inválido para %s.",
    },
    zhCN = {
        ["Import / Export"] = "导入 / 导出", ["Share or restore the currently active profile."] = "分享或还原当前启用的配置文件。", ["Export string"] = "导出字符串", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "点击此字段，然后按 Ctrl+A 和 Ctrl+C 复制当前配置文件。", ["Select for copying"] = "选择以复制", ["Select the export string, then press Ctrl+C to copy it."] = "选择导出字符串，然后按 Ctrl+C 复制。", ["Export string selected. Press Ctrl+C to copy it."] = "已选择导出字符串。按 Ctrl+C 复制。", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "无法选择导出字符串。点击此字段，然后按 Ctrl+A 和 Ctrl+C。", ["Import string"] = "导入字符串", ["Paste a BuffTimers profile string here."] = "在此粘贴 BuffTimers 配置文件字符串。", ["Import profile"] = "导入配置文件", ["A profile with this name already exists and will be replaced. Continue?"] = "已存在同名配置文件，将被替换。是否继续？", ["The profile was imported successfully."] = "配置文件导入成功。", ["Paste a profile string first."] = "请先粘贴配置文件字符串。", ["The profile string is too long."] = "配置文件字符串过长。", ["This is not a BuffTimers profile string."] = "这不是 BuffTimers 配置文件字符串。", ["This profile string uses an unsupported version (%s)."] = "此配置文件字符串使用了不受支持的版本（%s）。", ["The profile string is damaged or incomplete."] = "配置文件字符串已损坏或不完整。", ["The profile data is invalid."] = "配置文件数据无效。", ["The profile contains an invalid value for %s."] = "配置文件包含 %s 的无效值。",
    },
    zhTW = {
        ["Import / Export"] = "匯入 / 匯出", ["Share or restore the currently active profile."] = "分享或還原目前啟用的設定檔。", ["Export string"] = "匯出字串", ["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."] = "點擊此欄位，然後按 Ctrl+A 和 Ctrl+C 來複製目前的設定檔。", ["Select for copying"] = "選取以複製", ["Select the export string, then press Ctrl+C to copy it."] = "選取匯出字串，然後按 Ctrl+C 複製。", ["Export string selected. Press Ctrl+C to copy it."] = "已選取匯出字串。按 Ctrl+C 複製。", ["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."] = "無法選取匯出字串。點擊此欄位，然後按 Ctrl+A 和 Ctrl+C。", ["Import string"] = "匯入字串", ["Paste a BuffTimers profile string here."] = "在此貼上 BuffTimers 設定檔字串。", ["Import profile"] = "匯入設定檔", ["A profile with this name already exists and will be replaced. Continue?"] = "已存在同名設定檔，將會被取代。是否繼續？", ["The profile was imported successfully."] = "設定檔已成功匯入。", ["Paste a profile string first."] = "請先貼上設定檔字串。", ["The profile string is too long."] = "設定檔字串過長。", ["This is not a BuffTimers profile string."] = "這不是 BuffTimers 設定檔字串。", ["This profile string uses an unsupported version (%s)."] = "此設定檔字串使用不受支援的版本（%s）。", ["The profile string is damaged or incomplete."] = "設定檔字串已損壞或不完整。", ["The profile data is invalid."] = "設定檔資料無效。", ["The profile contains an invalid value for %s."] = "設定檔包含 %s 的無效值。",
    },
}

for locale, strings in pairs(profileStrings) do
    local localeTable = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", locale)
    if localeTable then
        for key, value in pairs(strings) do
            localeTable[key] = value
        end
    end
end
