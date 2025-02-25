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
    L["Text font size"] = "Text font size"
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
end

-- Russian translation
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ruRU")
if L then
    L["Show seconds"] = "Показать секунды"
    L["Show milliseconds below 5 seconds"] = "Показывать миллисекунды когда осталось меньше 5 секунд"
    L["Always yellow text color"] = "Всегда желтый цвет текста"
    L["Time Stamp Format"] = "Формат отметки времени"
    L["Add more colors to the timer"] = "Добавить больше цветов к таймеру"
    L["Text vertical position"] = "Вертикальное положение текста"
    L["Text font size"] = "Размер шрифта текста"
    L["Customize text"] = "Настроить текст"
    L["Adjust the font size of the timer text"] = "Настроить размер шрифта таймера"
    L["Adjust the vertical position of the timer text"] = "Настроить вертикальное положение текста таймера"
    L["Enable text customization"] = "Включить настройку текста"
    L["Use different colors based on remaining time"] = "Использовать разные цвета в зависимости от оставшегося времени"
    L["Always use yellow for buff timer text"] = "Всегда использовать желтый цвет для текста таймера баффа"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Показывать миллисекунды для таймеров баффов с меньше 5 секунд"
    L["Only show seconds when buffs have less than this many minutes"] = "Показывать секунды только когда баффы имеют меньше этого количества минут"
    L["Show seconds for buff timers"] = "Показывать секунды для таймеров баффов"
    L["Choose the format for displaying buff duration"] = "Выберите формат для отображения продолжительности баффа"
end

-- German translation by: ysjoelfir
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "deDE")
if L then
    L["Show seconds"] = "Sekunden anzeigen"
    L["Show milliseconds below 5 seconds"] = "Zeige Millisekunden unter 5 Sekunden"
    L["Always yellow text color"] = "Textfarbe immer gelb"
    L["Time Stamp Format"] = "Zeitstempelformat"
    L["Add more colors to the timer"] = "Füge mehr Farben zum Timer hinzu"
    L["Text vertical position"] = "Text vertikale Position"
    L["Text font size"] = "Text Schriftgröße"
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
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ptPT")
if locale == "ptPT" then
    L["Show seconds"] = "Mostrar segundos"
    L["Show milliseconds below 5 seconds"] = "Mostrar milisegundos abaixo de 5 segundos"
    L["Always yellow text color"] = "Cor de texto sempre amarela"
    L["Time Stamp Format"] = "Formato da hora"
    L["Add more colors to the timer"] = "Adicionar mais cores ao temporizador"
    L["Text vertical position"] = "Posição vertical do texto"
    L["Text font size"] = "Tamanho da fonte do texto"
    L["customize_text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar o tamanho da fonte do texto do temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar a posição vertical do texto do temporizador"
    L["Enable text customization"] = "Habilitar personalização de texto"
    L["Use different colors based on remaining time"] = "Usar cores diferentes com base no tempo restante"
    L["Always use yellow for buff timer text"] = "Texto sempre amarelo para o temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milissegundos para temporizadores de buff com menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos apenas quando os buffs têm menos deste número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escolha o formato para exibir a duração do buff"
end

-- French translation by: qrpino
local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "frFR")
if locale == "frFR" then
    L["Show seconds"] = "Afficher les secondes"
    L["Show milliseconds below 5 seconds"] = "Afficher les millisecondes sous 5 secondes"
    L["Always yellow text color"] = "Couleur du texte toujours jaune"
    L["Time Stamp Format"] = "Format de l'horodatage"
    L["Add more colors to the timer"] = "Ajouter plus de couleurs au minuteur"
    L["Text vertical position"] = "Position verticale du texte"
    L["Text font size"] = "Taille de la police du texte"
    L["customize_text"] = "Personnaliser le texte"
    L["Adjust the font size of the timer text"] = "Ajuster la taille de la police du texte du minuteur"
    L["Adjust the vertical position of the timer text"] = "Ajuster la position verticale du texte du minuteur"
    L["Enable text customization"] = "Activer la personnalisation du texte"
    L["Use different colors based on remaining time"] = "Utiliser différentes couleurs en fonction du temps restant"
    L["Always use yellow for buff timer text"] = "Texte toujours jaune pour le minuteur de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Afficher les millisecondes pour les minuteurs de buff avec moins de 5 secondes restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Afficher les secondes uniquement lorsque les buffs ont moins de ce nombre de minutes"
    L["Show seconds for buff timers"] = "Afficher les secondes pour les minuteurs de buff"
    L["Choose the format for displaying buff duration"] = "Choisir le format pour afficher la durée du buff"
end

--
-- HELP!
-- I need help with all the languages below.
-- Right now, everything has been translated by AI, so it might not be correct.
--

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "esES")
if locale == "esES" then
    L["Show seconds"] = "Mostrar segundos"
    L["Show milliseconds below 5 seconds"] = "Mostrar los milisegundos bajo 5 segundos"
    L["Always yellow text color"] = "Siempre color texto amarillo"
    L["Time Stamp Format"] = "Formato de la hora"
    L["Add more colors to the timer"] = "Añadir más colores al temporizador"
    L["Text vertical position"] = "Posición vertical del texto"
    L["Text font size"] = "Tamaño de fuente del texto"
    L["customize_text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar el tamaño de la fuente del texto del temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar la posición vertical del texto del temporizador"
    L["Enable text customization"] = "Habilitar la personalización del texto"
    L["Use different colors based on remaining time"] = "Usar colores diferentes según el tiempo restante"
    L["Always use yellow for buff timer text"] = "Texto siempre amarillo para el temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milisegundos para temporizadores de buff con menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos solo cuando los buffs tienen menos de este número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escoge el formato para mostrar la duración del buff"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "esMX")
if locale == "esMX" then
    L["Show seconds"] = "Mostrar segundos"
    L["Show milliseconds below 5 seconds"] = "Mostrar los milisegundos bajo 5 segundos"
    L["Always yellow text color"] = "Siempre color texto amarillo"
    L["Time Stamp Format"] = "Formato de la hora"
    L["Add more colors to the timer"] = "Añadir más colores al temporizador"
    L["Text vertical position"] = "Posición vertical del texto"
    L["Text font size"] = "Tamaño de fuente del texto"
    L["customize_text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar el tamaño de la fuente del texto del temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar la posición vertical del texto del temporizador"
    L["Enable text customization"] = "Habilitar la personalización del texto"
    L["Use different colors based on remaining time"] = "Usar colores diferentes según el tiempo restante"
    L["Always use yellow for buff timer text"] = "Texto siempre amarillo para el temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milisegundos para temporizadores de buff con menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos solo cuando los buffs tienen menos de este número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escoge el formato para mostrar la duración del buff"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "itIT")
if locale == "itIT" then
    L["Show seconds"] = "Mostra secondi"
    L["Show milliseconds below 5 seconds"] = "Mostra millisecondi sotto 5 secondi"
    L["Always yellow text color"] = "Sempre colore testo giallo"
    L["Time Stamp Format"] = "Formato dell'ora"
    L["Add more colors to the timer"] = "Aggiungi più colori al timer"
    L["Text vertical position"] = "Posizione verticale del testo"
    L["Text font size"] = "Dimensione del carattere del testo"
    L["customize_text"] = "Personalizza testo"
    L["Adjust the font size of the timer text"] = "Ajusta la dimensione del carattere del testo del timer"
    L["Adjust the vertical position of the timer text"] = "Ajusta la posizione verticale del testo del timer"
    L["Enable text customization"] = "Abilita la personalizzazione del testo"
    L["Use different colors based on remaining time"] = "Usa colori diversi in base al tempo rimanente"
    L["Always use yellow for buff timer text"] = "Testo sempre giallo per il timer di buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostra millisecondi per i timer di buff con meno di 5 secondi rimanenti"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostra solo secondi quando i buff hanno meno di questo numero di minuti"
    L["Show seconds for buff timers"] = "Mostra secondi per i timer di buff"
    L["Choose the format for displaying buff duration"] = "Scegli il formato per visualizzare la durata del buff"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "koKR")
if locale == "koKR" then
    L["Show seconds"] = "초 보기"
    L["Show milliseconds below 5 seconds"] = "5초 이하 마이크로초 보기"
    L["Always yellow text color"] = "항상 노란색 텍스트 색상"
    L["Time Stamp Format"] = "시간 표시 형식"
    L["Add more colors to the timer"] = "타이머에 더 많은 색상 추가"
    L["Text vertical position"] = "텍스트 수직 위치"
    L["Text font size"] = "텍스트 글꼴 크기"
    L["customize_text"] = "텍스트 사용자 정의"
    L["Adjust the font size of the timer text"] = "타이머 텍스트의 글꼴 크기 조정"
    L["Adjust the vertical position of the timer text"] = "타이머 텍스트의 수직 위치 조정"
    L["Enable text customization"] = "텍스트 사용자 정의 활성화"
    L["Use different colors based on remaining time"] = "남은 시간에 따라 다른 색상 사용"
    L["Always use yellow for buff timer text"] = "항상 노란색 텍스트 색상"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "5초 이하 마이크로초 보기"
    L["Only show seconds when buffs have less than this many minutes"] = "5초 이하 마이크로초 보기"
    L["Show seconds for buff timers"] = "초 보기"
    L["Choose the format for displaying buff duration"] = "초 보기"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "ptBR")
if locale == "ptBR" then
    L["Show seconds"] = "Mostrar segundos"
    L["Show milliseconds below 5 seconds"] = "Mostrar milisegundos abaixo de 5 segundos"
    L["Always yellow text color"] = "Sempre cor de texto amarela"
    L["Time Stamp Format"] = "Formato da hora"
    L["Add more colors to the timer"] = "Adicionar mais cores ao temporizador"
    L["Text vertical position"] = "Posição vertical do texto"
    L["Text font size"] = "Tamanho da fonte do texto"
    L["customize_text"] = "Personalizar texto"
    L["Adjust the font size of the timer text"] = "Ajustar o tamanho da fonte do texto do temporizador"
    L["Adjust the vertical position of the timer text"] = "Ajustar a posição vertical do texto do temporizador"
    L["Enable text customization"] = "Habilitar a personalização do texto"
    L["Use different colors based on remaining time"] = "Usar cores diferentes com base no tempo restante"
    L["Always use yellow for buff timer text"] = "Texto sempre amarelo para o temporizador de buff"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "Mostrar milissegundos para temporizadores de buff com menos de 5 segundos restantes"
    L["Only show seconds when buffs have less than this many minutes"] = "Mostrar segundos apenas quando os buffs têm menos deste número de minutos"
    L["Show seconds for buff timers"] = "Mostrar segundos para temporizadores de buff"
    L["Choose the format for displaying buff duration"] = "Escolha o formato para exibir a duração do buff"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "zhCN")
if locale == "zhCN" then
    L["Show seconds"] = "显示秒"
    L["Show seconds below this time"] = "小于此时间才显示秒"
    L["Show milliseconds below 5 seconds"] = "小于5秒显示毫秒"
    L["Always yellow text color"] = "文字颜色总是使用黄色"
    L["Time Stamp Format"] = "时间格式"
    L["Add more colors to the timer"] = "计时器显示更多颜色"
    L["Text vertical position"] = "文字垂直位置"
    L["Text font size"] = "字体大小"
    L["customize_text"] = "自定义文字"
    L["Adjust the font size of the timer text"] = "调整计时器文字大小"
    L["Adjust the vertical position of the timer text"] = "调整计时器文字垂直位置"
    L["Enable text customization"] = "启用文字自定义"
    L["Use different colors based on remaining time"] = "根据剩余时间使用不同颜色"
    L["Always use yellow for buff timer text"] = "文字颜色总是使用黄色"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "显示毫秒计时器，当剩余时间小于5秒时"
    L["Only show seconds when buffs have less than this many minutes"] = "只显示秒，当buff剩余时间小于此分钟数时"
    L["Show seconds for buff timers"] = "显示秒计时器"
    L["Choose the format for displaying buff duration"] = "选择显示buff持续时间的格式"
end

local L = LibStub("AceLocale-3.0"):NewLocale("BuffTimers", "zhTW")
if locale == "zhTW" then
    L["Show seconds"] = "顯示秒"
    L["Show seconds below this time"] = "小於此時間才顯示秒"
    L["Show milliseconds below 5 seconds"] = "小於5秒才顯示毫秒"
    L["Always yellow text color"] = "文字顔色總是使用黃色"
    L["Time Stamp Format"] = "時間格式"
    L["Add more colors to the timer"] = "計時器顯示更多顔色"
    L["Text vertical position"] = "文字垂直位置"
    L["Text font size"] = "字體大小"
    L["customize_text"] = "自定義文字"
    L["Adjust the font size of the timer text"] = "調整計時器文字大小"
    L["Adjust the vertical position of the timer text"] = "調整計時器文字垂直位置"
    L["Enable text customization"] = "啟用文字自訂"
    L["Use different colors based on remaining time"] = "根據剩餘時間使用不同顏色"
    L["Always use yellow for buff timer text"] = "文字顏色總是使用黃色"
    L["Show milliseconds for buff timers with less than 5 seconds remaining"] = "顯示毫秒計時器，當剩餘時間小於5秒時"
    L["Only show seconds when buffs have less than this many minutes"] = "只顯示秒，當buff剩餘時間小於此分鐘數時"
    L["Show seconds for buff timers"] = "顯示秒計時器"
    L["Choose the format for displaying buff duration"] = "選擇顯示buff持續時間的格式"
end
